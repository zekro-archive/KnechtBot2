<?php

require 'secrets.php';

header('Content-Type: application/json');


$pdo = new PDO(
    'mysql:host=' . DB_HOST . ';' .
    'dbname=' . DB_NAME . ';',
    DB_USERNAME,
    DB_PASSWORD
);


$query = 'SELECT * FROM stats';

$data = array();

$res = $pdo->query($query);


foreach ($res as $row) {
    $data[] = $row;
}

print json_encode($data);