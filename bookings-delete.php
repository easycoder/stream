<?php
// Delete a booking record by its data-relative path.
// Body: {path}  e.g. {"path": "2026/05/16/260516-Jane-Doe.json"}

session_start();
header('Content-Type: application/json; charset=utf-8');

if (empty($_SESSION['user'])) {
    http_response_code(401);
    echo json_encode(['status' => 'fail', 'error' => 'Not authenticated']);
    exit;
}

$body = json_decode(file_get_contents('php://input'), true);
if (!is_array($body) || empty($body['path'])) {
    http_response_code(400);
    echo json_encode(['status' => 'fail', 'error' => 'Bad request']);
    exit;
}

// Strict shape: YYYY/MM/DD/{slug}.json — blocks path traversal
if (!preg_match('@^\d{4}/\d{2}/\d{2}/[A-Za-z0-9-]+\.json$@', $body['path'])) {
    http_response_code(400);
    echo json_encode(['status' => 'fail', 'error' => 'Invalid path']);
    exit;
}

$file = __DIR__ . '/data/' . $body['path'];
if (!file_exists($file)) {
    http_response_code(404);
    echo json_encode(['status' => 'fail', 'error' => 'Not found']);
    exit;
}

if (!unlink($file)) {
    http_response_code(500);
    echo json_encode(['status' => 'fail', 'error' => 'Could not delete']);
    exit;
}

echo json_encode(['status' => 'ok']);
