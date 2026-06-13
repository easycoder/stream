<?php
session_start();
header('Content-Type: application/json');

$file = '../' . $_SERVER['HTTP_HOST'] . '.txt';

if (!file_exists($file)) {
    http_response_code(404);
    echo json_encode(['status' => 'fail', 'error' => 'Credentials file not found']);
    exit;
}

$stored = json_decode(trim(file_get_contents($file)), true);
if (!is_array($stored) || !isset($stored['user'], $stored['pass_hash'])) {
    http_response_code(500);
    echo json_encode(['status' => 'fail', 'error' => 'Credentials file malformed']);
    exit;
}

$body = json_decode(file_get_contents('php://input'), true);
if (!is_array($body) || !isset($body['user'], $body['pass'])) {
    http_response_code(400);
    echo json_encode(['status' => 'fail', 'error' => 'Bad request']);
    exit;
}

if (hash_equals($stored['user'], (string)$body['user'])
    && password_verify((string)$body['pass'], $stored['pass_hash'])) {
    $_SESSION['user'] = $stored['user'];
    echo json_encode(['status' => 'ok']);
} else {
    echo json_encode(['status' => 'fail']);
}
