<?php
header('Surrogate-Control: "ESI/1.0"');
header('Cache-Control: "max-age=0, public, s-maxage=0, must-revalidate"');
?>
<h1>ok</h1>

<esi:include src="/hola.html"/>
