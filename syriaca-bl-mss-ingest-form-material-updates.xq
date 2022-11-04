xquery version "3.1";


import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:path-to-repo := "/home/arren/Documents/GitHub/britishLibrary-data/";
declare variable $local:input-collection := collection($local:path-to-repo||"data/tei/");
declare variable $local:path-to-ingest-csv := "/home/arren/Documents/GitHub/sandbox/Syriaca_BL-Data_Form-Material-Normalization_ingest.csv";
declare variable $local:form-material-ingest-doc := 
    let $f := file:read-text($local:path-to-ingest-csv)
    return csv:parse($f, map{"header": "yes"});
    

for $row in $local:form-material-ingest-doc/*:csv/*
where $row/*:updatedForm/text() != "" or $row/*:updatedMaterialAttribute/text() != ""
for $doc in $local:input-collection
where "/"||substring-after(document-uri($doc), $local:path-to-repo) = $row/*:fileName/text()
let $msOrPartUri := $row/*:uri/text()
return 
  (if($row/*:updatedForm/text() !="") then 
    replace value of node $doc//msDesc//msIdentifier[idno[@type="URI"]/text() = $msOrPartUri]/../physDesc/objectDesc/@form with $row/*:updatedForm/text() 
    else (),
  if($row/*:updatedMaterialAttribute/text() !="") then 
    replace value of node $doc//msDesc//msIdentifier[idno[@type="URI"]/text() = $msOrPartUri]/../physDesc/objectDesc/supportDesc/@material with $row/*:updatedMaterialAttribute/text() 
    else ()
  )
 
