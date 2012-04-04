<?php 

 require("http.php");
 $http=new http_class;
 $url="http://twitter.com/statuses/public_timeline.json";
 
  /*
     *  If basic authentication is required, specify the user name and
     *  password in these variables.
     */

     $user="";
     $password="";
     $realm="";       /* Authentication realm or domain      */
     $workstation=""; /* Workstation for NTLM authentication */
     $authentication=(strlen($user) ? UrlEncode($user).":".UrlEncode($password)."@" : "");

     $error=$http->GetRequestArguments($url,$arguments);
     $arguments["Headers"]["Pragma"]="nocache";

    $error=$http->Open($arguments);
    if ($error=="")
    {
        $error=$http->SendRequest($arguments);

        if($error=="")
        {
            for(Reset($http->request_headers),$header=0;$header<count($http->request_headers);Next($http->request_headers),$header++)
            {
                $header_name=Key($http->request_headers);
                if(GetType($http->request_headers[$header_name])=="array")
                {
                    for($header_value=0;$header_value<count($http->request_headers[$header_name]);$header_value++)
                        echo $header_name.": ".$http->request_headers[$header_name][$header_value],"\r\n";
                }
                else
                    echo $header_name.": ".$http->request_headers[$header_name],"\r\n";
            }
            echo "</PRE>\n";
            flush();

            $headers=array();
            $error=$http->ReadReplyHeaders($headers);
            if($error=="")
            {
                echo "<H2><LI>Response status code:</LI</H2>\n<P>".$http->response_status;
                switch($http->response_status)
                {
                    case "301":
                    case "302":
                    case "303":
                    case "307":
                        echo " (redirect to <TT>".$headers["location"]."</TT>)<BR>\nSet the <TT>follow_redirect</TT> variable to handle redirect responses automatically.";
                        break;
                }
                echo "</P>\n";
                echo "<H2><LI>Response headers:</LI</H2>\n<PRE>\n";
                for(Reset($headers),$header=0;$header<count($headers);Next($headers),$header++)
                {
                    $header_name=Key($headers);
                    if(GetType($headers[$header_name])=="array")
                    {
                        for($header_value=0;$header_value<count($headers[$header_name]);$header_value++)
                            echo $header_name.": ".$headers[$header_name][$header_value],"\r\n";
                    }
                    else
                        echo $header_name.": ".$headers[$header_name],"\r\n";
                }
                echo "</PRE>\n";
                flush();

                echo "<H2><LI>Response body:</LI</H2>\n<PRE>\n";
                for(;;)
                {
                    $error=$http->ReadReplyBody($body,1000);
                    if($error!=""
                    || strlen($body)==0)
                        break;
                    echo HtmlSpecialChars($body);
                }
                echo "</PRE>\n";
                flush();
            }
        }
        $http->Close();
    }
    if(strlen($error))
        echo "<CENTER><H2>Error: ",$error,"</H2><CENTER>\n";
?>
</UL>
<HR>
</BODY>
</HTML>





httpclient
$json = '{"a":1,"b":2,"c":3,"d":4,"e":5}';



?>
