<?php

$host = "192.168.1.50";
$user = "root";
$pass = "123456";
$port = 3306;

$conn = new mysqli($host, $user, $pass, "", $port);

if ($conn->connect_error) {
    die("Error de conexión: " . $conn->connect_error);
}

echo "<h2>Conexión correcta a MariaDB</h2>";

$result = $conn->query("SHOW DATABASES");

echo "<h3>Bases de datos disponibles:</h3><ul>";
while ($row = $result->fetch_assoc()) {
    echo "<li>" . $row['Database'] . "</li>";
}
echo "</ul>";

$conn->close();
?>