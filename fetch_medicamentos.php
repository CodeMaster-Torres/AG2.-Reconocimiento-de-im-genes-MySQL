<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS, DELETE, PUT");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "med_db";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$sql = "SELECT * FROM medicamentos";
$result = $conn->query($sql);

$medicamentos = array();

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $medicamentos[] = $row;
    }
}

echo json_encode($medicamentos);

$conn->close();
?>
