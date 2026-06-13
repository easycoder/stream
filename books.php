<?php
// Read-only bookings viewer for the accountant.
// Access: https://stream.eclecity.net/books.php?key=Acct2026
// Replace "Acct2026" with a shared secret; change the secret below.

$validKey = 'Acct2026';
$key = isset($_GET['key']) ? trim($_GET['key']) : '';
if ($key !== $validKey) {
    http_response_code(403);
    echo '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Access denied</title>';
    echo '<style>body{font-family:sans-serif;padding:4em;text-align:center;color:#888}</style></head>';
    echo '<body><h2>Access denied</h2><p>Invalid or missing key.</p></body></html>';
    exit;
}

$dataDir = __DIR__ . '/data';
$rows = [];

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
        $rows[] = $record;
    }
}

// Sort by date descending
usort($rows, function ($a, $b) {
    $dateA = $a['date'] ?? '0000-00-00';
    $dateB = $b['date'] ?? '0000-00-00';
    if ($dateA !== $dateB) return strcmp($dateB, $dateA);
    return strcmp($b['slug'] ?? '', $a['slug'] ?? '');
});

// Group by financial year (Apr–Mar)
$fyGroups = [];
foreach ($rows as $r) {
    $d = $r['date'] ?? '';
    $y = (int)substr($d, 0, 4);
    $m = (int)substr($d, 5, 2);
    $fy = ($m >= 4) ? ($y . '-' . substr($y+1, -2)) : (($y-1) . '-' . substr($y, -2));
    $fyGroups[$fy][] = $r;
}
krsort($fyGroups);

function fmtPence($p) {
    $p = (int)$p;
    return '£' . number_format($p / 100, 2);
}

function fmtTenths($t) {
    $t = (int)$t;
    return number_format($t / 10, 1) . ' mi';
}

$totalMileage = 0;
$totalExpense = 0;
$totalFees = 0;

?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Filming accounts</title>
<style>
    * { box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 1em; background: #f5f5f5; color: #222; }
    h1 { font-weight: 400; font-size: 1.3em; margin: 0 0 0.2em; }
    .subtitle { color: #888; font-size: 0.85em; margin-bottom: 1.5em; }
    table { border-collapse: collapse; width: 100%; background: #fff; border-radius: 6px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.08); margin-bottom: 2em; font-size: 0.85em; }
    th { background: #eef; padding: 0.5em 0.6em; text-align: left; font-weight: 600; white-space: nowrap; border-bottom: 2px solid #ddd; }
    td { padding: 0.4em 0.6em; border-bottom: 1px solid #eee; vertical-align: top; }
    tr:hover td { background: #fafafa; }
    .fy-header td { background: #f0f4f8; font-weight: 700; border-top: 2px solid #aaa; border-bottom: 2px solid #aaa; font-size: 0.9em; }
    .num { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap; }
    .total-row td { background: #eef; font-weight: 700; border-top: 2px solid #333; }
    .doc-link { color: #28a; text-decoration: none; }
    .doc-link:hover { text-decoration: underline; }
    .kind-badge { display: inline-block; font-size: 0.75em; padding: 0.1em 0.4em; border-radius: 3px; background: #e8e8e8; }
    .kind-service { background: #d4edda; }
    .kind-expense { background: #f8d7da; }
    .kind-slideshow { background: #fff3cd; }
    .paid-yes { color: #080; }
    .paid-no { color: #aaa; }
    .grand-total td { background: #dde; font-weight: 700; border-top: 3px solid #333; font-size: 0.95em; }
    @media (max-width: 800px) {
        table { font-size: 0.75em; }
        th, td { padding: 0.3em 0.4em; }
        .hide-mobile { display: none; }
    }
</style>
</head>
<body>

<h1>Filming accounts</h1>
<p class="subtitle">All bookings &mdash; read-only view for the accountant</p>

<?php foreach ($fyGroups as $fy => $group): ?>
<?php
    $fyMileage = 0;
    $fyExpense = 0;
    $fyFees = 0;
    foreach ($group as $r) {
        $fyMileage += (int)($r['mileage'] ?? 0);
        $fyExpense += (int)($r['expense'] ?? 0);
        $fyFees += (int)($r['fees'] ?? 0);
    }
    $totalMileage += $fyMileage;
    $totalExpense += $fyExpense;
    $totalFees += $fyFees;
?>

<table>
<tr class="fy-header"><td colspan="9">FY <?php echo htmlspecialchars($fy); ?></td></tr>
<tr>
    <th>Date</th>
    <th>Name</th>
    <th class="hide-mobile">Location</th>
    <th>Kind</th>
    <th class="num">Mileage</th>
    <th class="num">Expense</th>
    <th class="num">Fees</th>
    <th class="num">Paid</th>
    <th>Doc</th>
</tr>
<?php foreach ($group as $r): ?>
<?php
    $kind = $r['kind'] ?? '';
    $kindClass = 'kind-' . $kind;
    $kindLabel = $kind === 'expense' ? 'Exp' : ($kind === 'slideshow' ? 'SS' : 'Svc');
    $paid = !empty($r['paid']);
?>
<tr>
    <td><?php echo htmlspecialchars($r['date'] ?? ''); ?></td>
    <td><?php echo htmlspecialchars($r['name'] ?? $r['deceased'] ?? ''); ?></td>
    <td class="hide-mobile"><?php echo htmlspecialchars($r['location'] ?? ''); ?></td>
    <td><span class="kind-badge <?php echo $kindClass; ?>"><?php echo $kindLabel; ?></span></td>
    <td class="num"><?php echo $r['mileage'] ? fmtTenths($r['mileage']) : ''; ?></td>
    <td class="num"><?php echo $r['expense'] ? fmtPence($r['expense']) : ''; ?></td>
    <td class="num"><?php echo $r['fees'] ? fmtPence($r['fees']) : ''; ?></td>
    <td class="num <?php echo $paid ? 'paid-yes' : 'paid-no'; ?>"><?php echo $paid ? '&#10003;' : '&#8212;'; ?></td>
    <td><?php if (!empty($r['document_url'])): ?><a class="doc-link" href="<?php echo htmlspecialchars($r['document_url']); ?>" target="_blank">&#128196;</a><?php endif; ?></td>
</tr>
<?php endforeach; ?>
<tr class="total-row">
    <td colspan="4">FY <?php echo htmlspecialchars($fy); ?> total</td>
    <td class="num"><?php echo fmtTenths($fyMileage); ?></td>
    <td class="num"><?php echo fmtPence($fyExpense); ?></td>
    <td class="num"><?php echo fmtPence($fyFees); ?></td>
    <td colspan="2"></td>
</tr>
</table>
<?php endforeach; ?>

<table>
<tr class="grand-total">
    <td colspan="4">Grand total</td>
    <td class="num"><?php echo fmtTenths($totalMileage); ?></td>
    <td class="num"><?php echo fmtPence($totalExpense); ?></td>
    <td class="num"><?php echo fmtPence($totalFees); ?></td>
    <td colspan="2"></td>
</tr>
</table>

<p style="color:#999;font-size:0.8em;margin-top:1em;">
Generated from filming records. Updated whenever bookings are saved.
</p>

</body>
</html>
