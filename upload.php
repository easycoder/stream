<?php
// Upload and serve document files for the filming admin.
//
// GET  /upload.php?date=YYYY-MM-DD          — show upload form
// POST /upload.php (multipart)               — upload file, return URL
// GET  /upload.php?path=YYYY/MM/DD/filename  — serve the file for viewing
//
// Files are stored in data/YYYY/MM/DD/{filename} alongside the booking JSON.
// Only authenticated admin users can upload; served files are public.

session_start();

// ── Serve an existing file ────────────────────────────────────────────
$servePath = isset($_GET['path']) ? trim($_GET['path']) : '';
if ($servePath !== '') {
    // Strict path validation: YYYY/MM/DD/{filename-with-optional-dots}
    if (!preg_match('#^\d{4}/\d{2}/\d{2}/.+$#', $servePath)) {
        http_response_code(400);
        echo "Invalid path";
        exit;
    }

    $file = __DIR__ . '/data/' . $servePath;
    if (!file_exists($file)) {
        http_response_code(404);
        echo "File not found";
        exit;
    }

    // Determine content type
    $ext = strtolower(pathinfo($file, PATHINFO_EXTENSION));
    $mimeTypes = [
        'jpg'  => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'png'  => 'image/png',
        'gif'  => 'image/gif',
        'pdf'  => 'application/pdf',
        'doc'  => 'application/msword',
        'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'xls'  => 'application/vnd.ms-excel',
        'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'txt'  => 'text/plain',
        'csv'  => 'text/csv',
    ];
    $contentType = $mimeTypes[$ext] ?? 'application/octet-stream';

    header('Content-Type: ' . $contentType);
    header('Content-Disposition: inline; filename="' . basename($file) . '"');
    header('Content-Length: ' . filesize($file));
    readfile($file);
    exit;
}

// ── Handle file upload (multipart POST) ──────────────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    header('Content-Type: text/html; charset=utf-8');

    if (empty($_SESSION['user'])) {
        echo '<p style="color:red">Not authenticated. <a href="/">Sign in first</a>.</p>';
        exit;
    }

    $date    = isset($_POST['date']) ? trim($_POST['date']) : '';
    $name    = isset($_POST['filename']) ? trim($_POST['filename']) : '';

    if ($date === '' || $name === '') {
        echo '<p style="color:red">Date and filename are required.</p>';
        exit;
    }

    // Validate date format
    if (!preg_match('/^(\d{4})-(\d{2})-(\d{2})$/', $date, $m)) {
        echo '<p style="color:red">Invalid date format (expected YYYY-MM-DD).</p>';
        exit;
    }

    // Check the uploaded file
    if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
        $errCode = $_FILES['file']['error'] ?? -1;
        echo '<p style="color:red">Upload failed (error code ' . $errCode . ').</p>';
        exit;
    }

    // Build the storage path: data/YYYY/MM/DD/{filename}
    // Keep the original extension from the uploaded file
    $uploadExt = strtolower(pathinfo($_FILES['file']['name'], PATHINFO_EXTENSION));
    $safeName  = $name;  // Keep user's filename as-is (spaces, hyphens, etc.)
    if ($uploadExt !== '') {
        // If user-provided name doesn't have the extension, append it
        if (strtolower(pathinfo($safeName, PATHINFO_EXTENSION)) !== $uploadExt) {
            $safeName .= '.' . $uploadExt;
        }
    }

    $relPath = sprintf('%s/%s/%s/%s', $m[1], $m[2], $m[3], $safeName);
    $dir     = __DIR__ . '/data/' . dirname($relPath);
    $dest    = __DIR__ . '/data/' . $relPath;

    if (!is_dir($dir) && !mkdir($dir, 0755, true)) {
        echo '<p style="color:red">Could not create directory.</p>';
        exit;
    }

    if (!move_uploaded_file($_FILES['file']['tmp_name'], $dest)) {
        echo '<p style="color:red">Could not save file.</p>';
        exit;
    }

    // URL to the uploaded file (for the document field)
    $fileUrl = '/upload.php?path=' . urlencode($relPath);

    echo '<!DOCTYPE html>';
    echo '<html lang="en"><head><meta charset="utf-8">';
    echo '<title>Upload complete</title>';
    echo '<style>
        body { font-family: sans-serif; padding: 2em; background: #f5f5f5; }
        .box { background: #fff; border: 1px solid #ddd; border-radius: 6px; padding: 1.5em; max-width: 40em; margin: 2em auto; }
        .url { background: #eef; padding: 0.5em; border: 1px solid #aac; border-radius: 4px; word-break: break-all; font-family: monospace; font-size: 1.1em; }
        .ok { color: #080; font-weight: bold; }
        .btn { display: inline-block; margin-top: 1em; padding: 0.5em 1em; background: #28a; color: #fff; border: 0; border-radius: 4px; text-decoration: none; cursor: pointer; font-size: 1em; }
    </style></head><body>';
    echo '<div class="box">';
    echo '<p class="ok">✓ Upload complete</p>';
    echo '<p><strong>File:</strong> ' . htmlspecialchars($safeName) . '</p>';
    echo '<p><strong>Stored at:</strong> ' . htmlspecialchars($relPath) . '</p>';
    echo '<p><strong>URL (copy this):</strong></p>';
    echo '<div class="url">' . htmlspecialchars($fileUrl) . '</div>';
    echo '<p><button class="btn" onclick="navigator.clipboard.writeText(\'' . htmlspecialchars($fileUrl, ENT_QUOTES) . '\').then(()=>this.textContent=\'Copied!\')">Copy URL</button>';
    echo ' <a class="btn" href="' . htmlspecialchars($fileUrl) . '" target="_blank">View file</a></p>';
    echo '</div></body></html>';
    exit;
}

// ── Show upload form (GET) ───────────────────────────────────────────
header('Content-Type: text/html; charset=utf-8');

if (empty($_SESSION['user'])) {
    echo '<p style="color:red">Not authenticated. <a href="/">Sign in first</a>.</p>';
    exit;
}

$presetDate = isset($_GET['date']) ? htmlspecialchars(trim($_GET['date'])) : '';
$presetName = isset($_GET['name']) ? htmlspecialchars(trim($_GET['name'])) : '';

?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Upload document</title>
<style>
    body {
        font-family: sans-serif;
        padding: 2em;
        background: #f5f5f5;
        margin: 0;
    }
    .box {
        background: #fff;
        border: 1px solid #ddd;
        border-radius: 6px;
        padding: 1.5em;
        max-width: 36em;
        margin: 2em auto;
    }
    h2 { margin-top: 0; color: #333; font-weight: 400; }
    label { display: block; margin: 0.8em 0 0.3em; font-size: 0.9em; color: #555; }
    input[type="text"], input[type="date"], input[type="file"] {
        width: 100%;
        padding: 0.4em;
        font-size: 1em;
        box-sizing: border-box;
        border: 1px solid #ccc;
        border-radius: 4px;
    }
    input[type="file"] { padding: 0.3em; }
    .hint { font-size: 0.8em; color: #888; margin-top: 0.2em; }
    .btn {
        display: inline-block;
        margin-top: 1em;
        padding: 0.5em 1.5em;
        background: #28a;
        color: #fff;
        border: 0;
        border-radius: 4px;
        font-size: 1em;
        cursor: pointer;
    }
    .btn:hover { background: #1a7; }
    .note { margin-top: 1.5em; font-size: 0.85em; color: #888; border-top: 1px solid #eee; padding-top: 1em; }
</style>
</head>
<body>
<div class="box">
<h2>Upload document</h2>
<form method="post" enctype="multipart/form-data">
    <label for="date">Date</label>
    <input type="date" id="date" name="date" value="<?php echo $presetDate; ?>" required>

    <label for="filename">Filename</label>
    <input type="text" id="filename" name="filename" value="<?php echo $presetName; ?>" placeholder="e.g. 260813 Print cartridge" required>
    <div class="hint">The full filename as it will appear in the folder. The original file extension is added automatically.</div>

    <label for="file">File</label>
    <input type="file" id="file" name="file" required>

    <button type="submit" class="btn">Upload</button>
</form>
<div class="note">
    After upload, the page will show a URL. Copy it and paste it into the
    <strong>Document URL</strong> field in the booking form.
</div>
</div>
</body>
</html>
