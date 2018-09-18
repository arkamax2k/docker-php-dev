<?php

$dsn = 'mysql:dbname=testdb;host=db';
$user = 'testuser';
$password = 'testpass';

$output = [];

$output[] = 'PHP version: ' . PHP_VERSION;

try {
    $pdo = new PDO($dsn, $user, $password);

    $dbVersion = $pdo
        ->query('SELECT VERSION()')
        ->fetch(PDO::FETCH_COLUMN, 0);

    $output[] = 'DB version: ' . $dbVersion;

} catch (PDOException $e) {
    $output[] = 'DB connection failed: ' . $e->getMessage();
}

if (!empty($_GET['send_email'])) {
    if (mail('testemail@qa.yourdomain.com', 'Test Email', 'Test Email Content')) {
        $output[] = 'Test email sent, <a href="http://localhost:1080/" target="_blank">click here</a>'
            .' to open MailCatcher';
    }
} else {
    $output[] = '<a href="' . $_SERVER['PHP_SELF'] . '?send_email=1" target="_blank">Click here</a>'
        . ' to send a test email';
}

echo implode('<br /><br />', $output);
