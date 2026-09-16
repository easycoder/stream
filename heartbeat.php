<?php
// Keep the admin session alive while a page stays open, and report whether
// that session is still valid.
//
// PHP deletes a session file once it has gone unwritten for
// session.gc_maxlifetime (1440 seconds — 24 minutes — with the defaults).
// An admin tab that is left open but idle makes no requests at all, so the
// session is collected while the user is away and the next save comes back
// as a 401 "Not authenticated": the page looks signed in but the server no
// longer knows who it is talking to.
//
// The admin page calls this endpoint every ten minutes, which is well inside
// the 24-minute window. Stamping the session forces the file to be rewritten
// (PHP's lazy_write skips a write when nothing has changed, so the stamp has
// to be a fresh value) and the garbage-collector's clock starts again.
//
// The reply doubles as an auth probe: the admin page asks after a failed save
// whether the session is still valid, which is how it tells an expired session
// apart from a server that is simply unreachable.

session_start();
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, no-cache, must-revalidate');

$authenticated = !empty($_SESSION['user']);

// Only stamp a session that belongs to a signed-in user. Stamping an
// anonymous visitor's would create a session file — and keep it alive — for
// every passing request to a page that was never signed in.
if ($authenticated) {
    $_SESSION['heartbeat'] = time();
}

echo json_encode([
    'status' => 'ok',
    'authenticated' => $authenticated ? 'yes' : 'no',
]);
