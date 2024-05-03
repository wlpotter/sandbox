xquery version "3.1";

import module namespace functx="http://www.functx.com";

import module namespace strfy="http://wlpotter.github.io/ns/strfy" at "https://raw.githubusercontent.com/wlpotter/xquery-utility-modules/main/stringify.xqm";

declare default element namespace "http://www.tei-c.org/ns/1.0";


declare variable $local:path-to-bl-data-repo := "/home/arren/Documents/GitHub/britishLibrary-data";

declare variable $local:in-coll := collection($local:path-to-bl-data-repo||"/data/tei/");

let $recs := 
  for $doc in $local:in-coll
  let $msUri := $doc//msDesc/msIdentifier/idno[@type="URI"]/text()
  let $msShelfmark :=$doc//msDesc/msIdentifier/altIdentifier/idno[@type="BL-Shelfmark"]/text()
  
  let $parts := if($doc//msDesc/msPart) then $doc//msPart else $doc//msDesc
  for $part in $parts
  let $partUri := $part/msIdentifier/idno[@type="URI"]/text()
  let $partMark := $part/msIdentifier/altIdentifier/idno[@type="BL-Shelfmark"]/text()
  
  for $hand in $part//handNote
  let $handId := $msUri||"#"||$hand/@xml:id/string()
  let $scope := $hand/@scope/string()
  let $script := $hand/@script/string()
  let $medium := $hand/@medium/string()
  let $desc := $hand//text() => string-join(" ") => normalize-space()
  let $childEls := for $el in $hand//* order by $el/name() return $el/name()
  let $childEls := distinct-values($childEls) => string-join("|")
  let $xmlString := strfy:stringify-node($hand, map {})
  return element {"rec"} {
    element {"msUri"} {$msUri},
    element {"msShelfmark"} {$msShelfmark},
    element {"partUri"} {$partUri},
    element {"partShelfMark"} {$partMark},
    element {"handId"} {$handId},
    element {"scope"} {$scope},
    element {"script"} {$script},
    element {"medium"} {$medium},
    element {"handDesc"} {$desc},
    element {"childElements"} {$childEls},
    element {"xmlAsString"} {$xmlString}
  }
return csv:serialize(<csv>{$recs}</csv>, map {"header": "yes"})