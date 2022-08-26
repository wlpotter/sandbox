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

declare function local:bibl-from-batch3($oldBibl as node())
as node()
{
  let $preamble := normalize-space(string-join($oldBibl//idno[@type="shelfmark"]//text(), " "))
  let $interim := 
    if($oldBibl/biblScope) then 
      let $biblScopePos := functx:index-of-deep-equal-node($oldBibl/child::node(), $oldBibl/biblScope)
      for $node at $i in $oldBibl/child::node()
      where ($node instance of text()) and $i < $biblScopePos
      return $node
    else ()
  let $interim := normalize-space(string-join($interim, " "))
  let $ptr := element Q{http://www.tei-c.org/ns/1.0}ptr {attribute {"target"} {$oldBibl//idno[@type="URL"]/text()}}
  let $citedRange := 
    if($oldBibl/biblScope) then
      let $locus := $oldBibl/biblScope/locus
      let $text := $locus/text()
      let $from := $locus/@from
      let $to := $locus/@to
      return element Q{http://www.tei-c.org/ns/1.0}citedRange {attribute {"unit"} {"fol"}, $from, $to, $text}
    else ()
  let $outro := 
      if($oldBibl/biblScope) then 
        let $biblScopePos := functx:index-of-deep-equal-node($oldBibl/child::node(), $oldBibl/biblScope)
        for $node at $i in $oldBibl/child::node()
        where ($node instance of text()) and $i > $biblScopePos
        return $node
    else normalize-space(string-join($oldBibl/text(), " "))
  return local:create-updated-bibl-record($preamble, $ptr, $interim, $citedRange, $outro)
  
      
};

(:
: Extends functx:dynamic-path to allow parsing of simple positional predicates
:)
declare function local:dynamic-path
  ( $parent as node() ,
    $path as xs:string )  as item()* {

  let $nextStep := functx:substring-before-if-contains($path,'/')
  let $predicate := substring-after($nextStep, '[')
  let $predicate := substring-before($predicate, ']')
  let $nextStep := functx:substring-before-if-contains($nextStep, '[')
  
  let $restOfSteps := substring-after($path,'/')
  for $child in
    ($parent/*[functx:name-test(name(),$nextStep)],
     $parent/@*[functx:name-test(name(),
                              substring-after($nextStep,'@'))])
  let $isMatch := ($predicate = "" or xs:integer($predicate) = functx:index-of-deep-equal-node($parent/*[functx:name-test(name(),$nextStep)], $child))
  
  return if ($isMatch) then 
           if ($restOfSteps)
           then local:dynamic-path($child, $restOfSteps)
           else $child
         else ()
 } ;
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
let $batch := $rec/*:status/text()
where $batch = "batch3"
let $matchingBibl := local:dynamic-path($doc, $rec/*:xpath/text())

(:local:create-updated-bibl-record($preamble as xs:string, $ptr as node(), $interim as xs:string?, $citedRange as node()?, $outro as xs:string?):)
return switch ($batch)
  case "batch1" return 
    (replace node $matchingBibl with
    local:create-updated-bibl-record(normalize-space(string-join($matchingBibl//text(), " ")), element Q{http://www.tei-c.org/ns/1.0}ptr {attribute {"target"} {$local:ms-uri-base||$rec/*:Uri-lookup/text()}}, "", (), ""),
    update:output(<success><msUri>{$msUri}</msUri><replacedNode>{functx:path-to-node-with-pos($matchingBibl)}</replacedNode></success>))
  case "batch2" return 
    (replace node $matchingBibl with
    local:create-updated-bibl-record(normalize-space(string-join($matchingBibl//text(), " ")), element Q{http://www.tei-c.org/ns/1.0}ptr {attribute {"target"} {$matchingBibl//idno/@ref/string()}}, "", (), ""), update:output(<success><msUri>{$msUri}</msUri><replacedNode>{functx:path-to-node-with-pos($matchingBibl)}</replacedNode></success>))
  case "batch3" return if($matchingBibl) then 
    (replace node $matchingBibl with local:bibl-from-batch3($matchingBibl),
    update:output(<success><msUri>{$msUri}</msUri><replacedNode>{functx:path-to-node-with-pos($matchingBibl)}</replacedNode></success>))
    else update:output(
      <error>
      <message>The following bibl was not updated because it could not be found:</message>
      <uri>{$msUri}</uri>
      <xpath>{$rec/*:xpath/text()}</xpath>
    </error>)
  default return ()
