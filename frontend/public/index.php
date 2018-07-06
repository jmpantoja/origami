<?php
header('Surrogate-Control: "ESI/1.0"');
header('Cache-Control: "max-age=1000, public, s-maxage=1000, must-revalidate"');
//http_response_code(500);
?>
<h1>ok   ???????</h1>

<esi:include src="/hola.html"/>
