<?php
// Reports whether the caller has an active admin session. Used by the
// public viewer to decide whether to show its "back to editor" button.
session_start();
header('Content-Type: application/json');
header('Cache-Control: no-store, no-cache, must-revalidate');
echo json_encode([
    'authenticated' => !empty($_SESSION['user']) ? 'yes' : 'no',
]);
