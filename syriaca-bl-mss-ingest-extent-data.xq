xquery version "3.1";

import module namespace functx="http://www.functx.com";


declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:path-to-repo :=
  "/home/arren/Documents/GitHub/britishLibrary-data";

declare variable $local:in-coll :=
  collection($local:path-to-repo||"/data/tei/");

declare variable $local:delimiter := ",";

declare variable $local:csv-in :=
  let $path-to-csv := "/home/arren/Documents/GitHub/sandbox/syriaca_BL-data_extent_ingest.csv"
  let $csv-string := file:read-text($path-to-csv)
  return csv:parse($csv-string, map {"header": "yes", "separator": $local:delimiter});
  

for $doc in $local:in-coll
let $docUri := substring-after(document-uri($doc), $local:path-to-repo)
let $extentData :=
  for $rec in $local:csv-in/*:csv/*:record
  where $rec/*:fileName/text() = $docUri
  return 
  <data>
    <uri>{$rec/*:msOrPartUri/text()}</uri>
    <extent>{$rec/*:Corrected_Extent/text()}</extent>
  </data>
for $e in $extentData
let $val := $e/*:extent/text()
where $val != "" (: skip cases of empty extents :)
let $label := if($val = 1) then " f." else " ff."
let $measure := element {"measure"} {
  attribute {"type"} {"composition"},
  attribute {"unit"} {"leaf"},
  attribute {"quantity"} {$val},
  $val||$label
}
let $target := $doc//objectDesc[../../msIdentifier/idno/text() = $e/*:uri/text()]
return 
  try
  { 
    if($target/supportDesc/extent/measure[@type="composition" or @unit="content_pending"]) then
      replace node $target/supportDesc/extent/measure[@type="composition" or @unit="content_pending"] with $measure
    else if($target/supportDesc/support) then
      insert node $measure after $target/supportDesc/support
    else
      insert node $measure as first into $target/supportDesc
  }
  catch * {
     let $failure :=
        element {"failure"} {
        element {"code"} {$err:code},
        element {"description"} {$err:description},
        element {"value"} {$err:value},
        element {"module"} {$err:module},
        element {"location"} {$err:line-number||": "||$err:column-number},
        element {"additional"} {$err:additional},
        element {"context"} {
          element {"file"} {$docUri},
          element {"msUri"} {$e/*:uri/text()}
        }
      }
    return update:output($failure)
  }