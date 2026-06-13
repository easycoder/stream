<?php
// Save (create or overwrite) a booking record — handles all fields from
// the merged admin form (service + stream + expense + slideshow).
//
// Body: JSON object with at minimum {slug, kind, date, ...}
// Writes to data/YYYY/MM/DD/{slug}.json (YYYY/MM/DD derived from date).

session_start();
header('Content-Type: application/json; charset=utf-8');

if (empty($_SESSION['user'])) {
    http_response_code(401);
    echo json_encode(['status' => 'fail', 'error' => 'Not authenticated']);
    exit;
}

$body = json_decode(file_get_contents('php://input'), true);
if (!is_array($body)) {
    http_response_code(400);
    echo json_encode(['status' => 'fail', 'error' => 'Bad request']);
    exit;
}

// Required fields every record must have
$required = ['slug', 'kind', 'date'];
foreach ($required as $key) {
    if (empty($body[$key])) {
        http_response_code(400);
        echo json_encode(['status' => 'fail', 'error' => "Missing required field: $key"]);
        exit;
    }
}

// Validate kind
$validKinds = ['service', 'expense', 'slideshow'];
if (!in_array($body['kind'], $validKinds)) {
    http_response_code(400);
    echo json_encode(['status' => 'fail', 'error' => 'Invalid kind: must be service, expense, or slideshow']);
    exit;
}

// Slug: alphanumerics and hyphens only — blocks path traversal
if (!preg_match('/^[A-Za-z0-9-]+$/', $body['slug'])) {
    http_response_code(400);
    echo json_encode(['status' => 'fail', 'error' => 'Invalid slug']);
    exit;
}

// Date must be YYYY-MM-DD
if (!preg_match('/^(\d{4})-(\d{2})-(\d{2})$/', $body['date'], $m)) {
    http_response_code(400);
    echo json_encode(['status' => 'fail', 'error' => 'Invalid date format (expected YYYY-MM-DD)']);
    exit;
}

$relPath = sprintf(
    '%s/%s/%s/%s.json',
    $m[1], $m[2], $m[3],
    $body['slug']
);
$dir = __DIR__ . '/data/' . dirname($relPath);
if (!is_dir($dir) && !mkdir($dir, 0755, true)) {
    http_response_code(500);
    echo json_encode(['status' => 'fail', 'error' => 'Could not create directory']);
    exit;
}

// Build the record with all merged fields.
// Fields default to empty string / false / 0 so every record has a
// consistent shape — the AllSpeak renderer never hits undefined values.
$record = [
    'slug'             => $body['slug'],
    'kind'             => $body['kind'],
    'date'             => $body['date'],

    // Viewer compatibility fields (mirror the fields stream-main.as reads)
    'deceased'         => $body['deceased']        ?? $body['name'] ?? '',
    'datetime'         => $body['datetime']        ?? (
        ($body['date'] ?? '') . 'T' . ($body['time'] ?? '00:00')
    ),

    // Account — service fields
    'time'             => $body['time']            ?? '',
    'name'             => $body['name']            ?? '',
    'location'         => $body['location']        ?? '',
    'postcode'         => $body['postcode']        ?? '',
    'distance'         => $body['distance']        ?? '',
    'contact'          => $body['contact']         ?? '',
    'client'           => $body['client']          ?? '',
    'client_email'     => $body['client_email']    ?? '',
    'mileage'          => (int)($body['mileage']   ?? 0),
    'expense'          => (int)($body['expense']   ?? 0),
    'fees'             => (int)($body['fees']      ?? 0),
    'paid'             => !empty($body['paid']),
    'paidDate'         => $body['paidDate']        ?? '',
    'linkSent'         => $body['linkSent']        ?? '',
    'invoiced'         => $body['invoiced']        ?? '',
    'link'             => $body['link']            ?? '',

    // Stream fields
    'title'            => $body['title']           ?? '',
    'dacast_id'        => $body['dacast_id']       ?? '',
    'stream_url'       => $body['stream_url']      ?? '',
    'recording_url'    => $body['recording_url']   ?? '',
    'contact_name'     => $body['contact_name']    ?? '',
    'contact_relation' => $body['contact_relation'] ?? '',
    'contact_telephone'=> $body['contact_telephone'] ?? '',
    'contact_email'    => $body['contact_email']   ?? '',
    'recording_text'   => $body['recording_text']  ?? '',
    'tribute_url'      => $body['tribute_url']     ?? '',
];

if (file_put_contents(
    __DIR__ . '/data/' . $relPath,
    json_encode($record, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)
) === false) {
    http_response_code(500);
    echo json_encode(['status' => 'fail', 'error' => 'Could not write file']);
    exit;
}

echo json_encode(['status' => 'ok', 'path' => $relPath]);
