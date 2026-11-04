<?php
// Clients lookup — the repeat clients, keyed by the unique combination of
// client rep and client company, kept in a single JSON file.
//
// GET  clients.php   → return clients.json. If the file does not exist yet,
//                      build it once from the booking records: group by the
//                      normalised company + rep pair, choose the most common
//                      spelling of each, and rewrite the bookings that used a
//                      different spelling. Phone and email are shared data on
//                      the client record; they do not rewrite historic bookings.
// POST clients.php   → save {clients:[...], renames:[{old_company, old_rep,
//                      company, rep}]}. Each rename is applied to every booking
//                      whose old company + rep matches.

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, no-cache, must-revalidate');

$clientsFile = __DIR__ . '/clients.json';
$dataDir = __DIR__ . '/data';

function cl_trim($s) {
    return trim((string)$s);
}

function cl_norm($s) {
    return strtolower(preg_replace('/\s+/', ' ', cl_trim($s)));
}

function cl_key($company, $rep) {
    return cl_norm($company) . "\x1f" . cl_norm($rep);
}

function cl_booking_files($dataDir) {
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

function cl_read_json($path) {
    $content = @file_get_contents($path);
    if ($content === false) {
        return null;
    }
    $data = json_decode($content, true);
    return is_array($data) ? $data : null;
}

function cl_write_json($path, $data) {
    $json = json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    return $json !== false && file_put_contents($path, $json) !== false;
}

function cl_sort(&$clients) {
    usort($clients, function ($a, $b) {
        $company = strcasecmp($a['company'], $b['company']);
        if ($company !== 0) {
            return $company;
        }
        return strcasecmp($a['rep'], $b['rep']);
    });
}

// Build the first clients.json from the booking records.
function cl_build($dataDir) {
    $records = [];
    foreach (cl_booking_files($dataDir) as $path) {
        $record = cl_read_json($path);
        if (!$record || empty($record['slug'])) {
            continue;
        }
        $company = cl_trim($record['client'] ?? '');
        $rep = cl_trim($record['contact'] ?? '');
        if ($company === '' && $rep === '') {
            continue;
        }
        $records[] = [
            'path' => $path,
            'data' => $record,
            'company' => $company,
            'rep' => $rep,
            'phone' => cl_trim($record['client_phone'] ?? ''),
            'email' => cl_trim($record['client_email'] ?? ''),
            'date' => (string)($record['date'] ?? ''),
        ];
    }

    $groups = [];
    foreach ($records as $i => $r) {
        $groups[cl_key($r['company'], $r['rep'])][] = $i;
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

    $clients = [];
    foreach ($groups as $indices) {
        $companyCandidates = [];
        $repCandidates = [];
        $phoneCandidates = [];
        $emailCandidates = [];
        foreach ($indices as $i) {
            $companyCandidates[$i] = $records[$i]['company'];
            $repCandidates[$i] = $records[$i]['rep'];
            if ($records[$i]['phone'] !== '') {
                $phoneCandidates[$i] = $records[$i]['phone'];
            }
            if ($records[$i]['email'] !== '') {
                $emailCandidates[$i] = $records[$i]['email'];
            }
        }

        $company = $choose($companyCandidates);
        $rep = $choose($repCandidates);
        $clients[] = [
            'company' => $company,
            'rep' => $rep,
            'phone' => $choose($phoneCandidates),
            'email' => $choose($emailCandidates),
        ];

        // Make the bookings agree with the spelling that was chosen.
        foreach ($indices as $i) {
            if ($records[$i]['company'] === $company && $records[$i]['rep'] === $rep) {
                continue;
            }
            $record = $records[$i]['data'];
            $record['client'] = $company;
            $record['contact'] = $rep;
            cl_write_json($records[$i]['path'], $record);
        }
    }

    cl_sort($clients);
    return $clients;
}

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

if ($method === 'GET') {
    $clients = null;
    if (is_file($clientsFile)) {
        $clients = cl_read_json($clientsFile);
    }
    if (!is_array($clients)) {
        $clients = cl_build($dataDir);
        if (!cl_write_json($clientsFile, $clients)) {
            http_response_code(500);
            echo json_encode(['status' => 'fail', 'error' => 'Could not write clients.json']);
            exit;
        }
    }
    echo json_encode($clients, JSON_UNESCAPED_UNICODE);
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
if (!is_array($body) || !isset($body['clients']) || !is_array($body['clients'])) {
    http_response_code(400);
    echo json_encode(['status' => 'fail', 'error' => 'Bad request']);
    exit;
}

$out = [];
$seen = [];
foreach ($body['clients'] as $client) {
    if (!is_array($client)) {
        continue;
    }
    $company = cl_trim($client['company'] ?? '');
    $rep = cl_trim($client['rep'] ?? '');
    if ($company === '' && $rep === '') {
        http_response_code(400);
        echo json_encode(['status' => 'fail', 'error' => 'A client needs a company or a rep']);
        exit;
    }
    $key = cl_key($company, $rep);
    if (isset($seen[$key])) {
        http_response_code(400);
        echo json_encode(['status' => 'fail', 'error' => 'Duplicate client: ' . $company . ' / ' . $rep]);
        exit;
    }
    $seen[$key] = true;
    $out[] = [
        'company' => $company,
        'rep' => $rep,
        'phone' => cl_trim($client['phone'] ?? ''),
        'email' => cl_trim($client['email'] ?? ''),
    ];
}

cl_sort($out);

// Global search/replace: apply each key change to every booking file.
$renamed = 0;
$renames = $body['renames'] ?? [];
if (is_array($renames)) {
    $files = cl_booking_files($dataDir);
    foreach ($renames as $rename) {
        if (!is_array($rename)) {
            continue;
        }
        $oldCompany = cl_trim($rename['old_company'] ?? '');
        $oldRep = cl_trim($rename['old_rep'] ?? '');
        $company = cl_trim($rename['company'] ?? '');
        $rep = cl_trim($rename['rep'] ?? '');
        if (cl_key($oldCompany, $oldRep) === cl_key($company, $rep)) {
            continue;
        }
        foreach ($files as $path) {
            $record = cl_read_json($path);
            if (!$record || empty($record['slug'])) {
                continue;
            }
            $recordCompany = cl_trim($record['client'] ?? '');
            $recordRep = cl_trim($record['contact'] ?? '');
            if (cl_key($recordCompany, $recordRep) === cl_key($oldCompany, $oldRep)) {
                $record['client'] = $company;
                $record['contact'] = $rep;
                if (cl_write_json($path, $record)) {
                    $renamed++;
                }
            }
        }
    }
}

if (!cl_write_json($clientsFile, $out)) {
    http_response_code(500);
    echo json_encode(['status' => 'fail', 'error' => 'Could not write clients.json']);
    exit;
}

echo json_encode(['status' => 'ok', 'renamed' => $renamed]);
