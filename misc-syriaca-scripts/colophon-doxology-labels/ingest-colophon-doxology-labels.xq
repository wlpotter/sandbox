xquery version "3.1";

import module namespace functx="http://www.functx.com";
import module namespace csv="http://basex.org/modules/csv";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:path-to-repo := "/home/arren/Documents/GitHub/britishLibrary-data/";

declare variable $local:path-to-csv-input := "/home/arren/Documents/GitHub/sandbox/misc-syriaca-scripts/colophon-doxology-labels/colophon-doxology-labels-for-ingest.csv";

let $csvString := file:read-text($local:path-to-csv-input)
let $dataToIngest := csv:parse($csvString, map {"header": "yes", "separator": "comma"})

(: ingest data is only those with a colophon or doxology :)
let $dataToIngest := 
  for $rec in $dataToIngest/*:csv/*:record
  where $rec/*:include/text() = "x"
  return $rec

for $doc in collection($local:path-to-repo)
let $msUri := $doc//msDesc/msIdentifier/idno/text()
let $matchingIngestData :=
  for $rec in $dataToIngest
  let $matchUri := if($rec/*:fixed_ms_level_uri/text()) then $rec/*:fixed_ms_level_uri/text() else $rec/*:ms_level_uri/text()
  where $msUri = $matchUri
  return $rec
(: return <el id="{$msUri}">{$matchingIngestData}</el> :)
for $rec in $matchingIngestData
let $matchId := if($rec/*:fixed_addition_xml-id/text() != "") then $rec/*:fixed_addition_xml-id/text() else $rec/*:addition_xml-id/text()

let $colophonLabel := if($rec/*:is_colophon/text() != "") then element {QName("http://www.tei-c.org/ns/1.0", "label")} {"Colophon"} else ()
let $doxLabel := if($rec/*:is_doxology/text() != "") then element {QName("http://www.tei-c.org/ns/1.0", "label")} {"Doxology"} else ()
return try {insert node ($colophonLabel, $doxLabel) as first into $doc//additions/list/item[@xml:id = $matchId]}
catch * {
  'Error [' || $err:code || ']: ' || $err:description  || '|| Affected item: ' || $msUri || "#" || $matchId
}
