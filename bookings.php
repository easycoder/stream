<?php
// List all bookings, optionally filtered by UK financial year.
// Returns full record objects sorted by date descending (newest first).
//
// Query params:
//   fy=2026-27   — filter to a UK financial year (1 Apr – 31 Mar)
//   (no fy)      — return all bookings
//
// A booking is any .json file directly under data/YYYY/MM/DD/.
// Each file is one record (service, expense, or slideshow).
//
// UK financial year: FY 2026-27 runs from 1 Apr 2026 to 31 Mar 2027.
// The FY filter matches records whose date falls in that range.

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, no-cache, must-revalidate');

$dataDir = __DIR__ . '/data';
$fyFilter = isset($_GET['fy']) ? trim($_GET['fy']) : '';

$bookings = [];

if (is_dir($dataDir)) {
    $iter = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($dataDir, RecursiveDirectoryIterator::SKIP_DOTS)
    );
    foreach ($iter as $file) {
        if (!$file->isFile() || $file->getExtension() !== 'json') {
            continue;
        }
        $content = file_get_contents($file->getPathname());
        $record = json_decode($content, true);
        if (!is_array($record) || empty($record['slug'])) {
            continue;
        }

        // Apply FY filter if set
        if ($fyFilter !== '') {
            $recordDate = $record['date'] ?? '';
            if ($recordDate === '') {
                continue;
            }
            // UK FY: YYYY-YY.  Parse the two year numbers.
            if (!preg_match('/^(\d{4})-(\d{2})$/', $fyFilter, $m)) {
                continue;  // malformed FY — skip
            }
            $fyStart = (int)$m[1];      // e.g. 2026
            $fyEnd   = $fyStart + 1;    // e.g. 2027 (but we only check 4-digit match below)

            // Extract year-month from record date (YYYY-MM-DD)
            if (!preg_match('/^(\d{4})-(\d{2})/', $recordDate, $dm)) {
                continue;
            }
            $recYear  = (int)$dm[1];
            $recMonth = (int)$dm[2];

            // UK FY: 1 Apr YYYY to 31 Mar YYYY+1
            $inFy = false;
            if ($recYear === $fyStart && $recMonth >= 4) {
                $inFy = true;
            } elseif ($recYear === $fyEnd && $recMonth <= 3) {
                $inFy = true;
            }
            if (!$inFy) {
                continue;
            }
        }

        // Include the relative path so the admin can construct write URLs
        $relativePath = str_replace(
            $dataDir . DIRECTORY_SEPARATOR,
            '',
            $file->getPathname()
        );
        $record['_path'] = str_replace(DIRECTORY_SEPARATOR, '/', $relativePath);

        $bookings[] = $record;
    }
}

// Sort by date descending (newest first); sub-sort by slug for stability
usort($bookings, function ($a, $b) {
    $dateA = $a['date'] ?? '0000-00-00';
    $dateB = $b['date'] ?? '0000-00-00';
    if ($dateA !== $dateB) {
        return strcmp($dateB, $dateA); // descending
    }
    $slugA = $a['slug'] ?? '';
    $slugB = $b['slug'] ?? '';
    return strcmp($slugB, $slugA); // descending
});

echo json_encode($bookings, JSON_UNESCAPED_UNICODE);
