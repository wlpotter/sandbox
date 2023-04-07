xquery version "3.0";


declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:path-to-repo :=
  "/home/arren/Documents/GitHub/britishLibrary-data";

declare variable $local:in-coll :=
  collection($local:path-to-repo||"/data/tei/");
  
let $recs :=
  for $doc in $local:in-coll
  let $fileUri := document-uri($doc)
  let $fileUri := substring-after($fileUri, $local:path-to-repo)
  
  for $physDesc in $doc//physDesc
  let $desc := $physDesc/p
  let $desc := normalize-space(string-join($desc//text(), " "))
  
  let $currentExtent := 
    if($physDesc/objectDesc/supportDesc/extent/measure[@type="composition"]) then
    $physDesc/objectDesc/supportDesc/extent/measure[@type="composition"]/@quantity/string()
    else ()
  
  let $uri := $physDesc/../msIdentifier/idno[@type="URI"]/text()
  return 
  <rec>
    <fileName>{$fileUri}</fileName>
    <msOrPartUri>{$uri}</msOrPartUri>
    <physDesc>{$desc}</physDesc>
    <currentExtent>{$currentExtent}</currentExtent>
  </rec>

return csv:serialize(<csv>{$recs}</csv>, map {"header": "yes"})  

