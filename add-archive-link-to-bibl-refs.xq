xquery version "3.1";

import module namespace functx="http://www.functx.com";


declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:path-to-repo :=
  "/home/arren/Documents/GitHub/britishLibrary-data";

declare variable $local:in-coll :=
  collection($local:path-to-repo||"/data/tei/");
  
declare variable $local:archive-url-bases :=
("https://archive.org/details/catalogueofsyria01brituoft/page/",
 "https://archive.org/details/catalogueofsyria02brituoft/page/",
 "https://archive.org/details/catalogueofsyria03brituoft/page/");


for $doc in $local:in-coll
  (: where not($doc//msPart) :)
  let $msUri := $doc//msDesc/msIdentifier/idno[@type="URI"]/text()
  where $msUri != "http://syriaca.org/manuscript/382" and $msUri != "http://syriaca.org/manuscript/383"
  for $bibl in $doc//additional/listBibl/bibl
  let $partUri := $bibl/../../../msIdentifier/idno[@type="URI"]/text()
  
  let $volumeAndPage := $bibl/citedRange[@unit="pp"]/text()
  let $volume := substring-before($volumeAndPage, ":")
  let $volume := if($volume = "I") then "1" else if ($volume = "II") then "2" else if ($volume = "III") then "3" else $volume
  let $page := substring-after($volumeAndPage, ":")
  let $startPage := normalize-space(functx:substring-before-if-contains($page, "-"))
  
  let $archiveLink :=
    switch($volume)
    case "1" return $local:archive-url-bases[1]
    case "2" return $local:archive-url-bases[2]
    case "3" return $local:archive-url-bases[3]
    default return "" 
  let $archiveLink := if($startPage != "") then $archiveLink||$startPage else ()
  
  let $ref := 
  element {"ref"} {
    attribute {"type"} {"internet-archive-pdf"},
    attribute {"target"} {$archiveLink}
  }
  
  return 
    try {insert node $ref as last into $bibl}
    catch * {
      let $failure :=
        element {"failure"} {
        element {"ms-uri"} {$msUri},
        element {"part-uri"} {$partUri},
        element {"code"} {$err:code},
        element {"description"} {$err:description},
        element {"value"} {$err:value},
        element {"module"} {$err:module},
        element {"location"} {$err:line-number||": "||$err:column-number},
        element {"additional"} {$err:additional}
      }
    return update:output($failure)
  }
  (: return if(ends-with($archiveLink, "/") or not($archiveLink)) then $msUri || " | " || $partUri else () :)