xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $csv-options := map{'header': true ()};

declare variable $app-data-manuscripts := 
  for $doc in collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\manuscripts\tei")
  return $doc;

declare variable $uris-on-app-data := 
  for $doc in $app-data-manuscripts
  return $doc//msIdentifier/idno[@type="URI"]/text();

declare variable $wright-catalogue-finalized-manuscripts := 
  let $allMss := collection("C:\Users\anoni\Documents\GitHub\srophe\wright-catalogue\data\5_finalized")
  for $doc in $allMss
  let $isOnDev := 
    for $uri in $doc//msIdentifier/idno[@type="URI"]/text()
    return if(functx:is-value-in-sequence($uri, $uris-on-app-data)) then "true" else ""
  let$isOnDev := string-join($isOnDev, "")
  return if($isOnDev = "") then $doc;

declare variable $wright-catalogue-drafted-manuscripts := 
  let $allMss := collection("C:\Users\anoni\Documents\GitHub\srophe\wright-catalogue\data\4_to_be_checked")
  for $doc in $allMss
  let $isOnDev := 
    for $uri in $doc//msIdentifier/idno[@type="URI"]/text()
    return if(functx:is-value-in-sequence($uri, $uris-on-app-data)) then "true" else ""
  let$isOnDev := string-join($isOnDev, "")
  return if($isOnDev = "") then $doc;
  
declare variable $all-mss-records := ($app-data-manuscripts, $wright-catalogue-finalized-manuscripts, $wright-catalogue-drafted-manuscripts);

declare variable $NUMBER-OF-MANUSCRIPT-RECORDS :=
  count($all-mss-records);


declare function local:get-attribute-name-list-used-on-element($element-name as xs:string, $node-sequence as node()+)
as xs:string*
{
  let $allAttr := 
    for $attr in $node-sequence//*[name() = $element-name]/@*
    return name($attr)
  return distinct-values($allAttr)
};

declare function local:get-distinct-xpaths-to-element-in-node-sequence($element-name as xs:string, $node-sequence as node()+)
as xs:string*
{
  let $allPaths := functx:path-to-node($node-sequence//*[name() = $element-name])
  
  (: collapse nested msItem duplicate paths and remove "/TEI/fileDesc/sourceDesc":)
  let $paths :=
    for $path in $allPaths
    let $path := "/"||substring-after($path, "sourceDesc")
    return replace($path, "(?:\/msItem)+", "/msItem", "j")
  return distinct-values($paths)
};

let $allMsDescElementNames := 
  for $doc in $all-mss-records
    for $el in $doc//msDesc/descendant-or-self::*
    return name($el)
let $distinctElementNames := distinct-values($allMsDescElementNames)

let $rows := 
  for $name in $distinctElementNames
  let $usedAttributes := local:get-attribute-name-list-used-on-element($name, $all-mss-records//msDesc)
  let $xpaths := local:get-distinct-xpaths-to-element-in-node-sequence($name, $all-mss-records//msDesc)
  let $count :=
    for $el in $all-mss-records//msDesc//*
    where name($el) = $name
    return $el
  let $count := count($count)
  
  return
  <row>
    <name>{$name}</name>
    <attributesUsed>{string-join($usedAttributes, "|")}</attributesUsed>
    <xpaths>{string-join($xpaths, "|")}</xpaths>
    <elementCount>{$count}</elementCount>
    <perRecordAverage>{$count div $NUMBER-OF-MANUSCRIPT-RECORDS}</perRecordAverage>
  </row>
return csv:serialize(<csv>{$rows}</csv>, $csv-options)