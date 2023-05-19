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

declare variable $local:editor-uri-base :=
  "http://syriaca.org/documentation/editors.xml#";
  
declare variable $local:editor-id := "kurban";

declare variable $local:editor-name := "Kurt Urban";

declare variable $local:resp-statement :=
  "Folio extent edited by";
  
declare variable $local:revisionDesc-change :=
  "CHANGED: added or corrected folio extent values";

let $resp :=
  element {"respStmt"} {
    element {"resp"} {$local:resp-statement},
    element {"name"} {
      attribute {"type"} {"person"},
      attribute {"ref"} {$local:editor-uri-base||$local:editor-id},
      $local:editor-name
    }
  }
let $change :=
  element {"change"} {
    attribute {"who"} {$local:editor-uri-base||$local:editor-id},
    attribute {"when"} {current-date()},
    $local:revisionDesc-change
  }

let $fileUris :=
  for $rec in $local:csv-in/*:csv/*:record
  return $rec/*:fileName/text()
let $fileUris := distinct-values($fileUris)

for $doc in $local:in-coll
let $docUri := substring-after(document-uri($doc), $local:path-to-repo)
where functx:is-value-in-sequence($docUri, $fileUris)
return (
  insert node $resp as last into $doc//titleStmt,
  replace value of node $doc//publicationStmt/date with current-date(),
  insert node $change as first into $doc//revisionDesc
)
