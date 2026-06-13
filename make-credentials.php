<?php
// One-time credentials generator for filming.eclecity.net
// Usage: ssh user@server 'php make-credentials.php'
// Then enter your desired username and password.

echo "Username: ";
$user = trim(fgets(STDIN));

echo "Password: ";
system('stty -echo');
$pass = trim(fgets(STDIN));
system('stty echo');
echo "\n";

if (!$user || !$pass) {
    echo "Both fields are required.\n";
    exit(1);
}

$hash = password_hash($pass, PASSWORD_BCRYPT);
$creds = json_encode([
    'user' => $user,
    'pass_hash' => $hash
], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);

$host = 'filming.eclecity.net';
$path = __DIR__ . '/../' . $host . '.txt';
file_put_contents($path, $creds . "\n");

echo "Credentials written to $path\n";
echo "User: $user\n";
