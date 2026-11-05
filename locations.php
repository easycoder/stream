<?php
// Locations lookup — the venues we visit more than once, kept in a single
// JSON file so a booking's Location, Postcode and Distance can be filled in
// without retyping them.
//
// GET  locations.php   → return data/locations.json. If the file does not
//                        exist yet, build it once from the booking records:
//                        group by postcode (and, for records without one, by
//                        name), choose the most common spelling of each name,
//                        and rewrite the bookings that used a different
//                        spelling so every record agrees.
// POST locations.php   → save {locations:[...], renames:[{from,to}]}. Each
//                        rename is applied to every booking file — the global
//                        search/replace performed when a location is renamed.

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, no-cache, must-revalidate');

$locationsFile = __DIR__ . '/data/locations.json';
$dataDir = __DIR__ . '/data';

function loc_trim($s) {
    return trim((string)$s);
}

function loc_norm_name($s) {
    return strtolower(preg_replace('/\s+/', ' ', loc_trim($s)));
}

function loc_norm_postcode($s) {
    return strtoupper(preg_replace('/\s+/', '', loc_trim($s)));
}

function loc_booking_files($dataDir) {
    $files = [];
    if (!is_dir($dataDir)) {
        return $files;
    }
    $iter = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($dataDir, RecursiveDirectoryIterator::SKIP_DOTS)
    );
    foreach ($iter as $file) {
        if ($file->isFile() && $file->getExtension() === 'json') {
            $files[] = $file->getPathname();
        }
    }
    return $files;
}

function loc_read_json($path) {
    $content = @file_get_contents($path);
    if ($content === false) {
        return null;
    }
    $data = json_decode($content, true);
    return is_array($data) ? $data : null;
}

function loc_write_json($path, $data) {
    $json = json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    return $json !== false && file_put_contents($path, $json) !== false;
}

function loc_ensure_data_dir($dataDir) {
    if (!is_dir($dataDir)) {
        return @mkdir($dataDir, 0755, true);
    }
    return true;
}

// Move a locations.json left at the site root by the earlier version.
function loc_migrate_legacy($locationsFile, $dataDir) {
    $legacy = __DIR__ . '/locations.json';
    if (is_file($locationsFile) || !is_file($legacy)) {
        return;
    }
    $data = loc_read_json($legacy);
    if (is_array($data) && loc_ensure_data_dir($dataDir) && loc_write_json($locationsFile, $data)) {
        @unlink($legacy);
    }
}

// Build the first data/locations.json from the booking records.
function loc_build($dataDir) {
    $records = [];
    foreach (loc_booking_files($dataDir) as $path) {
        $record = loc_read_json($path);
        if (!$record || empty($record['slug'])) {
            continue;
        }
        $name = loc_trim($record['location'] ?? '');
        if ($name === '') {
            continue;
        }
        $records[] = [
            'path' => $path,
            'data' => $record,
            'name' => $name,
            'postcode' => loc_trim($record['postcode'] ?? ''),
            'distance' => loc_trim($record['distance'] ?? ''),
            'date' => (string)($record['date'] ?? ''),
        ];
    }

    // Group by postcode; a record without one is grouped by name and folded
    // into a same-named postcode group when there is exactly one.
    $groups = [];
    $postcodeGroupsByName = [];
    foreach ($records as $i => $r) {
        $postcode = loc_norm_postcode($r['postcode']);
        if ($postcode !== '') {
            $key = 'pc:' . $postcode;
            if (!isset($groups[$key])) {
                $groups[$key] = ['records' => []];
            }
            $groups[$key]['records'][] = $i;
            $nameKey = loc_norm_name($r['name']);
            $postcodeGroupsByName[$nameKey][$key] = true;
        } else {
            $key = 'name:' . loc_norm_name($r['name']);
            if (!isset($groups[$key])) {
                $groups[$key] = ['records' => []];
            }
            $groups[$key]['records'][] = $i;
        }
    }
    foreach (array_keys($groups) as $key) {
        if (strpos($key, 'name:') !== 0) {
            continue;
        }
        $nameKey = substr($key, 5);
        if (!isset($postcodeGroupsByName[$nameKey])) {
            continue;
        }
        $postcodeKeys = array_keys($postcodeGroupsByName[$nameKey]);
        if (count($postcodeKeys) !== 1) {
            continue;
        }
        foreach ($groups[$key]['records'] as $i) {
            $groups[$postcodeKeys[0]]['records'][] = $i;
        }
        unset($groups[$key]);
    }

    // Pick the most common value; ties go to the most recent booking.
    $choose = function (array $candidates) use ($records) {
        $counts = [];
        $latest = [];
        foreach ($candidates as $i => $value) {
            if (!isset($counts[$value])) {
                $counts[$value] = 0;
                $latest[$value] = '';
            }
            $counts[$value]++;
            $date = $records[$i]['date'];
            if ($date > $latest[$value]) {
                $latest[$value] = $date;
            }
        }
        $best = '';
        $bestCount = 0;
        $bestDate = '';
        foreach ($counts as $value => $count) {
            if ($count > $bestCount || ($count === $bestCount && $latest[$value] > $bestDate)) {
                $best = $value;
                $bestCount = $count;
                $bestDate = $latest[$value];
            }
        }
        return $best;
    };

    $locations = [];
    foreach ($groups as $group) {
        $nameCandidates = [];
        $postcodeCandidates = [];
        $distanceCandidates = [];
        foreach ($group['records'] as $i) {
            $nameCandidates[$i] = $records[$i]['name'];
            if ($records[$i]['postcode'] !== '') {
                $postcodeCandidates[$i] = $records[$i]['postcode'];
            }
            if ($records[$i]['distance'] !== '') {
                $distanceCandidates[$i] = $records[$i]['distance'];
            }
        }

        $name = $choose($nameCandidates);
        $locations[] = [
            'name' => $name,
            'postcode' => $choose($postcodeCandidates),
            'distance' => $choose($distanceCandidates),
            'notes' => '',
        ];

        // Make the bookings agree with the spelling that was chosen.
        foreach ($group['records'] as $i) {
            if ($records[$i]['name'] === $name) {
                continue;
            }
            $record = $records[$i]['data'];
            $record['location'] = $name;
            loc_write_json($records[$i]['path'], $record);
        }
    }

    usort($locations, function ($a, $b) {
        return strcasecmp($a['name'], $b['name']);
    });
    return $locations;
}

loc_migrate_legacy($locationsFile, $dataDir);
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

if ($method === 'GET') {
    $locations = null;
    if (is_file($locationsFile)) {
        $locations = loc_read_json($locationsFile);
    }
    if (!is_array($locations)) {
        $locations = loc_build($dataDir);
        if (!loc_ensure_data_dir($dataDir) || !loc_write_json($locationsFile, $locations)) {
            http_response_code(500);
            echo json_encode(['status' => 'fail', 'error' => 'Could not write data/locations.json']);
            exit;
        }
    }
    echo json_encode($locations, JSON_UNESCAPED_UNICODE);
    exit;
}

if ($method !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'fail', 'error' => 'Method not allowed']);
    exit;
}

session_start();
if (empty($_SESSION['user'])) {
    http_response_code(401);
    echo json_encode(['status' => 'fail', 'error' => 'Not authenticated']);
    exit;
}

$body = json_decode(file_get_contents('php://input'), true);
if (!is_array($body) || !isset($body['locations']) || !is_array($body['locations'])) {
    http_response_code(400);
    echo json_encode(['status' => 'fail', 'error' => 'Bad request']);
    exit;
}

$out = [];
$seen = [];
foreach ($body['locations'] as $location) {
    if (!is_array($location)) {
        continue;
    }
    $name = loc_trim($location['name'] ?? '');
    if ($name === '') {
        http_response_code(400);
        echo json_encode(['status' => 'fail', 'error' => 'Every location needs a name']);
        exit;
    }
    $key = loc_norm_name($name);
    if (isset($seen[$key])) {
        http_response_code(400);
        echo json_encode(['status' => 'fail', 'error' => 'Duplicate location name: ' . $name]);
        exit;
    }
    $seen[$key] = true;
    $out[] = [
        'name' => $name,
        'postcode' => loc_trim($location['postcode'] ?? ''),
        'distance' => loc_trim($location['distance'] ?? ''),
        'notes' => (string)($location['notes'] ?? ''),
    ];
}

usort($out, function ($a, $b) {
    return strcasecmp($a['name'], $b['name']);
});

// Global search/replace: apply each renamed location to every booking file.
$renamed = 0;
$renames = $body['renames'] ?? [];
if (is_array($renames)) {
    $files = loc_booking_files($dataDir);
    foreach ($renames as $rename) {
        if (!is_array($rename)) {
            continue;
        }
        $from = loc_trim($rename['from'] ?? '');
        $to = loc_trim($rename['to'] ?? '');
        if ($from === '' || $to === '' || loc_norm_name($from) === loc_norm_name($to)) {
            continue;
        }
        foreach ($files as $path) {
            $record = loc_read_json($path);
            if (!$record || empty($record['slug'])) {
                continue;
            }
            $current = loc_trim($record['location'] ?? '');
            if ($current !== '' && loc_norm_name($current) === loc_norm_name($from)) {
                $record['location'] = $to;
                if (loc_write_json($path, $record)) {
                    $renamed++;
                }
            }
        }
    }
}

if (!loc_ensure_data_dir($dataDir) || !loc_write_json($locationsFile, $out)) {
    http_response_code(500);
    echo json_encode(['status' => 'fail', 'error' => 'Could not write data/locations.json']);
    exit;
}

echo json_encode(['status' => 'ok', 'renamed' => $renamed]);
