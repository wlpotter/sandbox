xquery version "3.1";

declare default element namespace "http://www.oxygenxml.com/ns/report";

import module namespace functx="http://www.functx.com";

let $doc := doc("C:\Users\anoni\Desktop\2022-02-03_mss-validation-errors-syriaca-main.xml")

let $descriptions := $doc/report/incident/description
let $uniqueDescriptions := functx:distinct-deep($descriptions)

let $totalIncidents := count($doc/report/incident)

let $items :=
   for $desc in $uniqueDescriptions
  let $matches :=
    for $incident in $doc/report/incident
    where $incident/description/text() = $desc/text()
    return $incident
  let $affectedFiles := $matches/systemID/text()
  let $affectedFiles := distinct-values($affectedFiles)
  let $affectedFileCount := count($affectedFiles)
  let $occurenceCount := count($matches)
  order by $occurenceCount descending
  return 
  <item>
  {
    $desc,
    <occurenceCount>{$occurenceCount}</occurenceCount>,
    <occurencePercent>{xs:float($occurenceCount) div xs:float($totalIncidents) * 100}</occurencePercent>,
    <affectedFileCount>{$affectedFileCount}</affectedFileCount>,
    <averageOccurenceInFiles>{xs:float($occurenceCount) div xs:float($affectedFileCount)}</averageOccurenceInFiles>
  }</item>

return csv:serialize(<csv>{$items}</csv>, map{"header": "yes"})
(:
Output a document (CSV?) that has all the unique errors, assigns them an ID, and gives counts, etc.
Output a a CSV version of the incident report
:)