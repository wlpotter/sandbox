xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:path-to-repo := "/home/arren/Documents/GitHub/britishLibrary-data/";
declare variable $local:input-collection := collection($local:path-to-repo||"data/tei/");


let $recs :=
  for $doc in $local:input-collection
  let $msUri := $doc//publicationStmt/idno/text() => substring-before("/tei")
  
  for $origDate in $doc//origin/origDate
  let $msOrPartUri := $origDate/../../../msIdentifier/idno[@type="URI"]/text()
  let $pdfLink := $origDate/../../../additional/listBibl/bibl/ref[@type="internet-archive-pdf"]/@target/string()
  let $uniquePath := functx:path-to-node-with-pos($origDate)
  
  let $attrInfo := 
  (
    element {"notBefore"} {$origDate/@notBefore/string()},
    element {"notAfter"} {$origDate/@notAfter/string()},
    element {"when"} {$origDate/@when/string()},
    element {"calendar"} {$origDate/@calendar/string()},
    element {"datingMethod"} {$origDate/@datingMethod/string()},
    element {"when-custom"} {$origDate/@when-custom/string()},
    element {"notBefore-custom"} {$origDate/@notBefore-custom/string()},
    element {"notAfter-custom"} {$origDate/@notAfter-custom/string()},
    element {"from"} {$origDate/@from/string()},
    element {"to"} {$origDate/@to/string()},
    element {"notAfter-after"} {$origDate/@notAfter-after/string()},
    element {"dating-Method"} {$origDate/@dating-Method/string()},
    element {"calender"} {$origDate/@calender/string()},
    element {"to-custom"} {$origDate/@to-custom/string()}
    )
  
  let $textNodeInfo := element {"textNode"} {$origDate//text() => string-join(" ") => normalize-space()}
  
  return 
  <rec>
  {
    element {"msUri"} {$msUri},
    element {"msOrPartUri"} {$msOrPartUri},
    element {"pdfLink"} {$pdfLink},
    element {"UniqueXpath"} {$uniquePath},
    $attrInfo,
    $textNodeInfo
  }
  </rec>
  
return csv:serialize(<csv>{$recs}</csv>, map {"header": "yes"})