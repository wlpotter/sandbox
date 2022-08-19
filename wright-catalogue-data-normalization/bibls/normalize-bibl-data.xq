xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:path-to-repo := "/home/arren/Documents/GitHub/britishLibrary-data/";

declare variable $local:collection :=
  collection($local:path-to-repo||"data/tei/");

declare variable $local:ms-uri-base := "http://syriaca.org/manuscript/";

declare variable $local:batch-1-csv-uri := "/home/arren/Documents/GitHub/sandbox/wright-catalogue-data-normalization/bibls/2022-08-17_bl-data_main_bibls-of-MSS_need-uri-match.csv";

declare variable $local:all-csv-uri := "/home/arren/Documents/GitHub/sandbox/wright-catalogue-data-normalization/bibls/2022-08-17_bl-data_main_bibls-of-MSS_ALL.csv";

declare function local:create-updated-bibl-record($preamble as xs:string, $ptr as node(), $interim as xs:string?, $citedRange as node()?, $outro as xs:string?)
as node()
{
  let $interim := if($interim != "") then normalize-space($interim)||" " else $interim
  let $outro := if($outro != "") then " "||$outro else $outro
  return element {QName("http://www.tei-c.org/ns/1.0", "bibl")}
  {
    $preamble,
    $ptr,
    $interim,
    $citedRange,
    $outro
  }
};

(: File Ingest and Setup :)

(: read in batch 1 data :)
let $batch1CsvDoc := file:read-text($local:batch-1-csv-uri)
let $batch1CsvDoc :=  csv:parse($batch1CsvDoc, map {"header": "yes", "separator": "comma"})

(: read in other csv data :)
let $allBatchesCsvDoc := file:read-text($local:all-csv-uri)
let $allBatchesCsvDoc :=  csv:parse($allBatchesCsvDoc, map {"header": "yes", "separator": "comma"})

(: filter for just batch 2 and 3 :)
let $recordsToProcess :=
  for $rec in $allBatchesCsvDoc/*:csv/*:record
  where $rec/*:status/text() = "batch2" or $rec/*:status/text() = "batch3"
  return $rec
(: collate with batch 1 data :)
let $recordsToProcess := ($recordsToProcess, $batch1CsvDoc/*:csv/*:record)

for $doc in $local:collection
let $msUri := $doc//msDesc/msIdentifier/idno/text()
for $rec in $recordsToProcess
where $msUri = $rec/*:ms-uri/text()
return $rec/*:xpath/text()
(:
- if batch 1, preamble is what's in the matching bibl's text node. ptr is gotten from the Uri-lookup field plus the URI base. no interim, citedRange, or outro.
- if batch 2, preamble is the combined, space normalized children. ptr is gotten from idno/@ref. no interim, citedRange, or outro
- if batch 3, preamble is what's in the shelfmark (idno[@type="shelfmark"]). ptr is gotten from the idno[@type="URL"]. if there's a biblScope, then interim is any text directly in the bibl (or maybe anything before the biblScope and directly under the bibl, if we can do that concisely). citedRange can be gotten from the biblScope/locus, with the script-supplied unit="fol". outro is either anything after the biblScope or any text outside of the idnos if there is no biblScope.
:)

