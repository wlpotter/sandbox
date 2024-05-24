xquery version "3.1";


import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";


declare variable $path-to-repo := "/home/arren/Documents/GitHub/britishLibrary-data/";

declare variable $in-coll := collection($path-to-repo||"data/tei/");

declare variable $origDate-csv-uri := "/home/arren/Documents/GitHub/sandbox/smbl_origDate_ingest.csv";

declare variable $origDate-csv :=
  let $f := file:read-text($origDate-csv-uri)
  return csv:parse($f, map {"header": "yes", "separator": "tab"});

declare variable $syriaca-ms-uri-base := "http://syriaca.org/manuscript/";

declare variable $smbl-uri-base := "https://bl.syriac.uk/ms/";

declare function local:add-leading-zeroes($date as xs:string) as xs:string {
  let $zeroes := "0000"
  let $zeroesNeeded := 4 - string-length($date)
  return substring($zeroes, 1, $zeroesNeeded)||$date
};

declare function local:create-origDate-nodes($recs as node()*)
as node()*
{
  for $r in $recs
  let $calendar := attribute {"calendar"} {$r/*:calendar/text()}
  let $datingMethod := if($r/*:datingMethod/text() != "") then attribute {"datingMethod"} {$r/*:datingMethod/text()} else ()
  let $notBefore := if($r/*:notBefore/text() != "") then attribute {"notBefore"} {local:add-leading-zeroes($r/*:notBefore/text())} else ()
  let $notAfter := if($r/*:notAfter/text() != "") then attribute {"notAfter"} {local:add-leading-zeroes($r/*:notAfter/text())} else ()
  let $when := if($r/*:when/text() != "") then attribute {"when"} {local:add-leading-zeroes($r/*:when/text())} else ()
  let $notBeforeCustom := if($r/*:notBefore-custom/text() != "") then attribute {"notBefore-custom"} {local:add-leading-zeroes($r/*:notBefore-custom/text())} else ()
  let $notAfterCustom := if($r/*:notAfter-custom/text() != "") then attribute {"notAfter-custom"} {local:add-leading-zeroes($r/*:notAfter-custom/text())} else ()
  let $whenCustom := if($r/*:when-custom/text() != "") then attribute {"when-custom"} {local:add-leading-zeroes($r/*:when-custom/text())} else ()
  let $text := $r/*:text/text()
  return element {QName("http://www.tei-c.org/ns/1.0", "origDate")} {
    $calendar,
    $datingMethod,
    $notBefore,
    $notAfter,
    $when,
    $notBeforeCustom,
    $notAfterCustom,
    $whenCustom,
    $text
  }
};

declare function local:create-error-msg($dates as node()*, $contextUri as xs:string)
as node() {
  element {"error"} {
    element {"recordContext"} {$contextUri},
    element {"dates"} {$dates}
  }
};
(:
- go through these part sections and check the number of origDates vs instances
- create updated origDate elements based on csv rows
- update the nodes there
:)
let $msUris := distinct-values($origDate-csv/*:csv/*:record/*:msUri)
let $msUris :=
  for $uri in $msUris
  return replace($uri, $syriaca-ms-uri-base, $smbl-uri-base)

let $partUris := distinct-values($origDate-csv/*:csv/*:record/*:msOrPartUri)
let $msUris :=
  for $uri in $msUris
  return replace($uri, $syriaca-ms-uri-base, $smbl-uri-base)

let $collatedDates :=
  for $m in $msUris
  let $assocDates := $origDate-csv/*:csv/*:record[replace(*:msUri/text(), $syriaca-ms-uri-base, $smbl-uri-base) = $m]
  let $partUris := distinct-values($assocDates/*:msOrPartUri)
  let $partUris :=
    for $uri in $partUris
    return replace($uri, $syriaca-ms-uri-base, $smbl-uri-base)
  return 
    <ms uri="{$m}">
      {for $p in $partUris
       return 
         <part uri="{$p}">
           {$assocDates[replace(*:msOrPartUri/text(), $syriaca-ms-uri-base, $smbl-uri-base) = $p]}
         </part>}
      </ms>

for $doc in $in-coll
let $msUri := $doc//msDesc/msIdentifier/idno/text()
(: where $msUri = "https://bl.syriac.uk/ms/10" :)
let $msDates := $collatedDates[@uri/string() = $msUri]
return if($doc//msPart) then
  for $part in $doc//msPart
  let $partUri := $part/msIdentifier/idno/text()
  let $partDates := $collatedDates/*:part[@uri/string() = $partUri]
  
  let $origDates := local:create-origDate-nodes($partDates/*:record)
  return if(count($origDates) = count($part/history/origin/origDate)and not(empty($part/history/origin/origDate))) then
     (delete node $part/history/origin/origDate, insert node $origDates as first into $part/history/origin)
     else update:output(local:create-error-msg($partDates, $partUri))
else
  let $partDates := $collatedDates/*:part[@uri/string() = $msUri]
  let $origDates := local:create-origDate-nodes($partDates/*:record)
  return if(count($origDates) = count($doc//msDesc/history/origin/origDate) and not(empty($doc//msDesc/history/origin/origDate))) then
    (delete node $doc//msDesc/history/origin/origDate, insert node $origDates as first into $doc//msDesc/history/origin)
    else update:output(local:create-error-msg($partDates, $msUri))