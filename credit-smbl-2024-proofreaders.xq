xquery version "3.1";

(:
: Given an input CSV and a directory of TEI files,
: inserts editor, respStmt, and/or change log messages
: for work done based on the file name and editor info
: supplied in the CSV
:
:
:)

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

(: I/O variables :)

declare variable $path-to-records :=
  "/home/arren/Documents/GitHub/britishLibrary-data/data/tei";
  
(: path to the CSV document containing the list of editors associated with each record
   also gives their associated role. Header configuration set by the $headers-config variable :)
declare variable $path-to-resp-csv :=
  "/home/arren/Documents/GitHub/sandbox/credit-smbl2024-proofreaders.csv";

(: CSV file location for the list of editor IDs and the corresponding names :)
(: headers should be 'editorId' and 'editorName' :)
declare variable $path-to-editors-info-csv := 
  "/home/arren/Documents/GitHub/sandbox/smbl2024-proofreader-info.csv";

(:~ ~~~~~~~~~~~~~~~~~~~~~~~~~ :)
(: Syriaca and BL metadata :)

declare variable $editors-uri-base := "https://bl.syriac.uk/documentation/editors.xml#";

(:~ ~~~~~~~~~~~~~~~~~~~~~~~~~ :)
(: Additional Configuration :)

(: maps a standard set of header names to the ones specific to the resp CSV (located at $path-to-resp-csv) :)
declare variable $resp-csv-headers-config :=
  map {
    "fileName": "fileName",
    "editorId": "editorId",
    "role": "role"
  };
  
(: maps a set of editor roles as keys to a map containing the respStmt, editor role, and change log info :)
declare variable $editor-role-metadata-config := 
  map {
    "review-editor": map {
      "editorRole": "review-editor",
      "resp": "Editorial review by"
    },
    "workshop-participant": map {
      "editorRole": "",
      "resp": "Record proofreading by"
    },
    "student": map {
      "editorRole": "",
      "resp": "Record proofreading by"
    }
  };

(:~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~ :)
(: XML collection and CSV parsing based on I/O variables  :)
(: note: do not edit; paths to these files can be changed above :)

declare variable $record-collection :=
  collection($path-to-records);
  
declare variable $resp-csv :=
  csv:parse(file:read-text($path-to-resp-csv), map {"header": "yes"});  

declare variable $editors-info-csv := 
  csv:parse(file:read-text($path-to-editors-info-csv), map {"header": "yes"});


(: MAIN SCRIPT :)
(: get the list of file names used in the resp CSV for filtering purposes :)
let $fileNamesInCsv := $resp-csv/*:csv/*:record/*[name() = $resp-csv-headers-config?fileName]/text()
let $fileNamesInCsv := distinct-values($fileNamesInCsv)

for $rec in $record-collection

(: only look at records that have a file name referenced in the CSV :)
let $recFileName := functx:substring-after-last(document-uri($rec), "/")
where functx:is-value-in-sequence($recFileName, $fileNamesInCsv)

(: add editor info to the record based on the matching CSV rows :)
for $row in $resp-csv/*:csv/*:record
where $row/*[name() = $resp-csv-headers-config?fileName]/text() = $recFileName

(:
- get the editorId
- get the editorName for that ID from the $editors-info-csv
- get the editor role (using the headers config)
- based on the editor role, add the editor element and respStmt element
:)


(: get the editorId from the row, then find related information from the editors-info-csv :)
let $editorId := $row/*[name() = $resp-csv-headers-config?editorId]/text()
let $editorName := $editors-info-csv/*:csv/*:record[*:editorId = $editorId]/*:editorName/text()

(: get the editor role from the row, then create the elements needed based on that role :)
let $projectRole := $row/*[name() = $resp-csv-headers-config?role]/text()

(: if the editor role has an associated role value for the tei:editor element, create that element :)
(: if there is no associated role value, don't create an element at all :)
let $editorElement :=
  if($editor-role-metadata-config?($projectRole)?editorRole != "") then
    element {QName("http://www.tei-c.org/ns/1.0", "editor")}{
    attribute {"role"} {$editor-role-metadata-config?($projectRole)?editorRole},
    attribute {"ref"} {$editors-uri-base||$editorId},
    $editorName 
  }
  else ()


let $respStmtElement :=
  if($editor-role-metadata-config?($projectRole)?resp != "") then
    element {QName("http://www.tei-c.org/ns/1.0", "respStmt")}{
      element {QName("http://www.tei-c.org/ns/1.0", "resp")}
        {
          $editor-role-metadata-config?($projectRole)?resp
        },
      element {QName("http://www.tei-c.org/ns/1.0", "name")}
        {
          attribute {"type"} {"person"},
          attribute {"ref"} {$editors-uri-base||$editorId}, 
          $editorName
        }
    }
  else ()

(: maybe add change log? :)
(: <change who="https://bl.syriac.uk/documentation/editors.xml#kurban" when="2023-04-21-05:00">CHANGED: added or corrected folio extent values</change> :)
(: let $changeLogElement :=
  element {QName("http://www.tei-c.org/ns/1.0", "change")}{
    attribute {"who"} {$editors-uri-base||$editorId},
    attribute {"when"} {current-date()},
    $change-log-msg
  } :)

(: return ($editorElement, $respStmtElement) :)

(: Update the record with the editor and respStmt elements :)
return
  (insert node $respStmtElement as last into $rec//titleStmt,
  if($editorElement and not($rec//titleStmt/editor[@type=$editorElement/@role/string()][@ref/string() = $editorElement/@ref/string()]))
  then insert node $editorElement before $rec//titleStmt/respStmt[1] else ()(: ,
  replace value of node $rec//publicationStmt/date with current-date() :)
)
(:
REVISE: checking the editors should check the role against the role in the editor element and not assume 'creator'
return 
  (insert node $respStmts as last into $rec//titleStmt,
  insert node $changeLogs as first into $rec//revisionDesc,
  if($creatorEditor and not($rec//titleStmt/editor[@type="creator"][@ref/string() = $creatorEditor/@ref/string()]))
  then insert node $creatorEditor before $rec//titleStmt/respStmt[1] else (),
  replace value of node $rec//publicationStmt/date with current-date()
)
:)