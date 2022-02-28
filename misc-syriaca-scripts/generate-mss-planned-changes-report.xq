xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare namespace srophe="https://srophe.app";
declare default element namespace "http://www.tei-c.org/ns/1.0";

let $inColl := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\manuscripts\tei")

let $plannedChangesByRecord :=
  for $doc in $inColl
  let $docUri := $doc//msDesc/msIdentifier/idno[@type="URI"]/text()
  let $plannedChanges := $doc//revisionDesc/change[@type="planned"]
  return
    <record uri="{$docUri}">{$plannedChanges}</record>
    
let $numberOfRecords := count($plannedChangesByRecord)
let $numberOfPlannedChanges := count($plannedChangesByRecord/change)

let $typesOfChanges := $plannedChangesByRecord/change/@subtype
let $typesOfChanges := distinct-values($typesOfChanges)

let $data := 
  for $type in $typesOfChanges
  let $totalChangesOfType := count($plannedChangesByRecord/change[@subtype= $type])
  let $percentOfTotalPlannedChanges :=xs:float($totalChangesOfType) div xs:float($numberOfPlannedChanges)
  
  let $averageChangePerFile := xs:float($totalChangesOfType) div xs:float($numberOfRecords)
  
  let $numberOfAffectedFiles := count($plannedChangesByRecord[change[@subtype = $type]])
  let $percentOfAffectedFiles := xs:float($numberOfAffectedFiles) div xs:float($numberOfRecords)
  
  return 
  <change>
    <type>{$type}</type>
    <numberOfInstances>{$totalChangesOfType}</numberOfInstances>
    <percentOfTotalPlannedChanges>{$percentOfTotalPlannedChanges}</percentOfTotalPlannedChanges>
    <numberOfAffectedFiles>{$numberOfAffectedFiles}</numberOfAffectedFiles>
    <percentOfAffectedFiles>{$percentOfAffectedFiles}</percentOfAffectedFiles>
    <averageChangePerFile>{$averageChangePerFile}</averageChangePerFile>
  </change>

return csv:serialize(<csv>{$data}</csv>, map{"header": "true"})