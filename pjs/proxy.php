<?php
// PHP Proxy
// Loads a file from any location.
// Author:Paulo Fierro
// January 29, 2006
// usage: proxy.php?url=http://mysite.com/myxml.xml

$session = curl_init($_GET['url']);                    
curl_setopt($session, CURLOPT_HEADER, false);          
curl_setopt($session, CURLOPT_RETURNTRANSFER, true);   
$xml = curl_exec($session);                            
echo $xml;            
curl_close($session);

?>
