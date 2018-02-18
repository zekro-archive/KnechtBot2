<?php

header('Content-Type: application/json');

define('DB_HOST', '');
define('DB_USERNAME', '');
define('DB_PASSWORD', '');
define('DB_NAME', '');


$mysqli = new mysqli(DB_HOST, DB_USERNAME, DB_PASSWORD, DB_NAME);

if(!$mysqli){
	die("Connection failed: " . $mysqli->error);
}

$query = sprintf("SELECT * FROM test");

$result = $mysqli->query($query);

$data = array();
foreach ($result as $row) {
	$data[] = $row;
}

$result->close();

$mysqli->close();

print json_encode($data);