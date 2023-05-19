xquery version "3.1";

import module namespace mshead="http://srophe.org/srophe/mshead" at "mshead.xqm";
import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:path-to-repo := "/home/arren/Documents/GitHub/britishLibrary-data/";

declare variable $local:input-collection := collection($local:path-to-repo||"/data/tei/");

for $doc in $local:input-collection
for $ms in $doc//*[name() = "msDesc" or name() = "msPart"]
let $shelfmark := $ms/msIdentifier/altIdentifer/idno[@type="BL-Shelfmark"]/text()
let $uri := $ms/msIdentifier/idno/text()
let $noHeadError := "No head element for "||$shelfmark||" ["||$uri||"]"
return 
  if($ms/head/note[@type="contents-note"]) then 
    replace node $ms/head/note[@type="contents-note"] with mshead:generate-contents-note($ms)
  else if ($ms/head) then
    insert node mshead:compose-head-element($ms) as first into $ms/head
  else update:output($noHeadError)