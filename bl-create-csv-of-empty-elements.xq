xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:path-to-repo := "/home/arren/Documents/GitHub/britishLibrary-data/";
declare variable $local:input-collection := collection($local:path-to-repo||"data/tei/");


let $recs :=
  for $doc in $local:input-collection
  let $msUri := $doc//publicationStmt/idno/text() => substring-before("/tei")
  
  for $el in $doc//msDesc//*
  where not($el/@*) and not($el/*) and (string-join($el/text(), "") => normalize-space() = "")
  let $descOrPart := $el/ancestor::*[name() = "msPart" or name() = "msDesc"][1]
  let $msOrPartUri := $descOrPart/msIdentifier/idno[@type="URI"]/text()
  
  let $pdfLink := $descOrPart/additional/listBibl/bibl/ref[@type="internet-archive-pdf"]/@target/string() 
  let $uniquePath := functx:path-to-node-with-pos($el)
  let $genericPath := functx:path-to-node($el)
  
  return 
  <rec>
    <msUri>{$msUri}</msUri>
    <partUri>{$msOrPartUri}</partUri>
    <pdfLink>{$pdfLink}</pdfLink>
    <nodeName>{$el/name()}</nodeName>
    <uniquePath>{$uniquePath}</uniquePath>
    <genericPath>{$genericPath}</genericPath>
  </rec>
  return csv:serialize(<csv>{$recs}</csv>, map {"header": "yes"})