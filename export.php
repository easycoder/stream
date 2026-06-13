<?php
// Export bookings as a CSV download for the accountant.
// Lists all records with financial data in a spreadsheet-friendly format.

session_start();
header('Content-Type: text/csv; charset=utf-8');
header('Content-Disposition: attachment; filename="bookings.csv"');

if (empty($_SESSION['user'])) {
    http_response_code(401);
    echo "Not authenticated";
    exit;
}

$dataDir = __DIR__ . '/data';

$out = fopen('php://output', 'w');

// CSV header row
fputcsv($out, [
    'Date', 'Name / Description', 'Location', 'Kind',
    'Mileage (tenths)', 'Expense (pence)', 'Fees (pence)', 'Paid',
    'Client', 'Contact', 'Slug'
]);

if (is_dir($dataDir)) {
    $iter = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($dataDir, RecursiveDirectoryIterator::SKIP_DOTS)
    );
    $rows = [];
    foreach ($iter as $file) {
        if (!$file->isFile() || $file->getExtension() !== 'json') {
            continue;
        }
        $content = file_get_contents($file->getPathname());
        $record = json_decode($content, true);
        if (!is_array($record)) {
            continue;
        }
        $rows[] = [
            $record['date'] ?? '',
            $record['name'] ?? $record['description'] ?? '',
            $record['location'] ?? '',
            $record['kind'] ?? '',
            $record['mileage'] ?? 0,
            $record['expense'] ?? 0,
            $record['fees'] ?? 0,
            $record['paid'] ? 'Yes' : 'No',
            $record['client'] ?? '',
            $record['contact'] ?? $record['contact_name'] ?? '',
            $record['slug'] ?? '',
        ];
    }

    // Sort by date ascending
    usort($rows, function ($a, $b) {
        return strcmp($a[0], $b[0]);
    });

    foreach ($rows as $row) {
        fputcsv($out, $row);
    }
}

fclose($out);
