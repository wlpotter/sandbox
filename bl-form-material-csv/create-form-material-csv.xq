xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:path-to-repo := "/home/arren/Documents/GitHub/britishLibrary-data";

let $recs :=

  for $doc in collection($local:path-to-repo||"/data/tei")
  let $docId := document-uri($doc)
  let $docId := substring-after($docId, $local:path-to-repo)
  
  for $partOrDesc in $doc//*[name() = "msDesc" or name() = "msPart"]
  let $uri := $partOrDesc/msIdentifier/idno/text()
  let $shelfmark := $partOrDesc/msIdentifier/altIdentifier/idno[@type="BL-Shelfmark"]/text()
  
  let $form := $partOrDesc/physDesc/objectDesc/@form/string()
  let $materialAttr := $partOrDesc/physDesc/objectDesc/supportDesc/@material/string()
  let $materialTextNode := $partOrDesc/physDesc/objectDesc/supportDesc/support/material/text()
  let $materialTextNode := string-join($materialTextNode, "|")
  let $physDesc := $partOrDesc/physDesc/p//text()
  let $physDesc := normalize-space(string-join($physDesc, " "))
    
  return
  <record>
    <fileName>{$docId}</fileName>
    <uri>{$uri}</uri>
    <shelfmark>{$shelfmark}</shelfmark>
    <form>{$form}</form>
    <materialAttribute>{$materialAttr}</materialAttribute>
    <materialTextNode>{$materialTextNode}</materialTextNode>
    <physicalDescription>{$physDesc}</physicalDescription>
  </record>
return csv:serialize(<csv>{$recs}</csv>, map {"header": "yes"})