<?php
header('Surrogate-Control: "ESI/1.0"');
header('Cache-Control: "max-age=100, public, s-maxage=100, must-revalidate"');


$servername = "localhost";
$username = "origami";
$password = "origami";

// Create connection
$conn = new mysqli($servername, $username, $password);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
echo "<hr/>";
echo "Connected successfully";
echo "<hr/>";

?>

<esi:include src="/hola.html" />