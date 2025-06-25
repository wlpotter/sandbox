xquery version "3.1";

module namespace ingest="http://wlpotter.github.io/ns/syriaca-ingest/ingest";
import module namespace functx = "http://www.functx.com" at "https://www.datypic.com/xq/functx-1.0.1-doc.xq";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare %updating function ingest:update-existing-records-with-new-data($existing-data as item()+, $data-to-ingest as item()+, $entity-type as xs:string) {
  
  for $item in $data-to-ingest?*
  let $matchedDoc := $existing-data[TEI/teiHeader/fileDesc/publicationStmt/idno[@type="URI"]/text() = $item?uri||"/tei"]
  let $docId := $item?uri => functx:substring-after-last("/")
  
  let $biblIdOffset := ingest:get-id-offset($matchedDoc//body//bibl)
  
  let $ingestBibls := $item?bibls
  
  (: TBD: append to the list of existing bibls using xquery update :)
  let $newBibls := if(map:size($ingestBibls) > 0) then ingest:create-new-bibls-with-ids($ingestBibls, $docId, $biblIdOffset) else ()
  
  (: TBD: implement a controller function or something to handle places vs persons... :)
  return (
    ingest:ingest-series-of-sourced-elements($item?place_names, $matchedDoc//place/placeName, "place_name", $docId, $biblIdOffset),
    ingest:ingest-series-of-sourced-elements($item?gps, $matchedDoc//place/location[@type="gps"], "gps", $docId, $biblIdOffset),
    insert node $newBibls after $matchedDoc//body//bibl[last()]
  )

};

declare function ingest:create-new-bibls-with-ids($bibls, $idBase as xs:string, $offset as xs:integer? := 0){
  for $k in map:keys($bibls)
  let $bibId := "bib"||$idBase||"-"||$k+$offset
  let $bib := map:get($bibls, $k)
  
  return element {$bib/name()} {
    $bib/@*,
    attribute {"xml:id"} {$bibId},
    $bib/*
  }
};

(:
Compares a sequence of zero or more sourced data items to a sequence of existing data nodes, updating source info for matches, or inserting new nodes for new data
@param $items is a sequence of maps of values and their sources
@param $toCompare is a sequence of elements from existing data records against which each item in $items will be compared to determine if updates are needed
@param $elementType is used to determine ; values must be "place_names", "gps", etc. TBD: full enum of allowed values
@param $docId represents the numerical portion of the URI for the record from which the $toCompare sequence derives
@param $biblIdOffset is an integer representing the the value to add to the sequential enumeration of the sources in the $items maps, offsets the bibl id, e.g. "#bib78-5"
:)
declare %updating function ingest:ingest-series-of-sourced-elements($items as item()*, $toCompare as item()*, $elementType as xs:string, $docId as xs:string, $biblIdOffset as xs:integer? := 0) {
  let $itemsLength := count($items)
  let $initialCompareMap := 
    for $el in $toCompare
         return {
           "original_node": $el,
           "updated_node": $el,
           "abs_path": functx:path-to-node-with-pos($el)
         }
  let $initialCompareMap := ($initialCompareMap, [])
  let $updatesMap := ingest:prepare-element-data-for-ingest($items, $itemsLength, $initialCompareMap, $elementType, $docId, $biblIdOffset)
    => ingest:post-process-data-for-ingest($elementType, $docId)
    
  return ingest:process-updates-from-ingest($updatesMap, $toCompare)
};

(:
A recursive function used to prepare data for being ingested, returns a map of existing nodes and their updated replacements, along with an array of the elements that should be inserted
:)
declare function ingest:prepare-element-data-for-ingest($items as item()*, $itemsLength as xs:integer, $compareMap as item()+, $elementType as xs:string, $docId as xs:string, $biblIdOffset as xs:integer? := 0) 
as item()*
{
  if($itemsLength = 0) then () (: if there are no items, skip this :)
  else if($itemsLength = 1) then
    ingest:ingest-single-item($items[1], $compareMap, $elementType, $docId, $biblIdOffset)
  else
    ingest:prepare-element-data-for-ingest($items[position() > 1], $itemsLength - 1, ingest:ingest-single-item($items[1], $compareMap, $elementType, $docId, $biblIdOffset), $elementType, $docId, $biblIdOffset)
};

declare function ingest:ingest-single-item($item as item(), $compareMap as item()*, $elementType as xs:string, $docId as xs:string, $biblIdOffset as xs:integer? := 0) {
  
  let $source := ingest:create-source-string($item?sources, $docId, $biblIdOffset)
  let $updatedMap :=
   for $m in $compareMap
    where $m instance of map(*)
    return if ($item?value = $m?updated_node//text() => string-join(" ") => normalize-space()) then 
      {
        "original_node": $m?original_node,
        "updated_node": ingest:update-element-source-attribute($m?updated_node, $source),
        "abs_path": $m?abs_path
      }
    else $m
  
  let $matches := 
    for $m in $compareMap
    where $m instance of map(*)
    where $item?value = $m?updated_node//text() => string-join(" ") => normalize-space()
    return 1
  let $newItems := for $m in $compareMap where $m instance of array(*) return $m (: get the array of new elements :)
  let $newItems := if(count($matches) < 1) then array:append($newItems, ingest:create-new-element($item?value, $elementType, $source, $docId)) else $newItems
  (: $contents as xs:string, $elementType as xs:string, $source as xs:string, $docId as xs:string, $idSeq as xs:int := 1):)
  return ($updatedMap, $newItems)
};

declare function ingest:post-process-data-for-ingest($updatesMap as item()*, $elementType as xs:string, $docId as xs:string)
as item()* {
  switch($elementType)
    case "place_name" return ingest:update-xml-ids($updatesMap, "name", $docId)
    case "gps" return $updatesMap (: TBD: create function to handle subtype for preferred/alternate :)
    default return $updatesMap
      (:
  TBD: switch statement for additional processing needed, e.g. xml:id sequence or subtypes for gps
  - case: place_names needs xml:id processing based on max ID in the updatesMap
  - case: gps needs subtypes applied based on counts of existing and new in $updatesMap
  :)
};

declare function ingest:update-xml-ids($updatesMap as item()*, $idPrefix as xs:string, $docId as xs:string)
as item()*
{
 let $idOffset := max(
   for $m in $updatesMap
   where $m instance of map(*)
   return $m?updated_node/@xml:id/string() => substring-after("-") => xs:integer()
 )
 for $m in $updatesMap
 return 
   if($m instance of map(*)) then $m
   else [
     for $item at $i in $m?*
     return functx:add-or-update-attributes($item, xs:QName("xml:id"), $idPrefix||$docId||"-"||($i+$idOffset)) 
  ]
};

declare %updating function ingest:process-updates-from-ingest($updatesMap as item()*, $compareList as item()*) {
  for $m in $updatesMap
  return if ($m instance of map(*)) then replace node $m?original_node with $m?updated_node (: update the existing nodes :)
  else for $el in $m?* return insert node $el after $compareList[last()] (: insert the new ones found in the array :)
  (:
  TBD: handle cases where compare list is empty --> maybe a default path for where each element should go?
  :)
};


declare function ingest:create-source-string($sourceSeq as xs:integer*, $docId as xs:string, $biblIdOffset as xs:integer? := 0)
as xs:string {
  let $sources := 
    for $s in $sourceSeq
    return "#bib"||$docId||"-"||($s + $biblIdOffset)
  return string-join($sources, " ") => normalize-space()
};

declare function ingest:update-element-source-attribute($element as element(), $sourceToAppend as xs:string)
as element()
 {
    if($element/@source) then (: add the new sources to the existing source attribute :)
      functx:add-or-update-attributes($element, QName("", "source"), string-join(($element/@source, $sourceToAppend), " ") => normalize-space())
    else if ($element/@resp) then (: if only a @resp, then if new sources, replace @resp with @source; otherwise keep the @resp :)
      if ($sourceToAppend != "") then
        functx:add-attributes(functx:remove-attributes($element, "resp"), QName("", "source"), $sourceToAppend)
      else $element (: if there is a resp, and no new sources to add, just retain the resp as-is :)
    else (: if there is no source or resp, then add a source if we have new ones, or a resp if we don't TBD: defaulting to syriaca.org URI for the resp (hard-coded) :)
      if ($sourceToAppend != "") then 
        functx:add-attributes($element, QName("", "source"), $sourceToAppend)
      else
        functx:add-attributes($element, QName("", "resp"), "http://syriaca.org")
};

declare function ingest:get-id-offset($elements as element()*)
as xs:integer? {
  max(
      for $el in $elements
      return $el/@xml:id/string() => substring-after("-") => xs:integer()
    )
};

(:
TBD: xml:lang for places...default to English
:)
declare function ingest:create-new-element($contents as xs:string, $elementType as xs:string, $source as xs:string, $docId as xs:string, $idSeq as xs:int := 1) {
  let $sourceAttr := if($source != "") then attribute {"source"} {$source} else attribute {"resp"} {"http://syriaca.org"}
  return 
    switch($elementType)
    (: NOTE: xml:id is added as a post-processing step before applying the xquery update functions :)
    case "place_name" return element {QName("http://www.tei-c.org/ns/1.0", "placeName")} {
      attribute {"xml:lang"} {"en"}, (:TBD: defaults to English; should be able to override :)
      $sourceAttr,
      $contents
    }
    case "gps" return element {QName("http://www.tei-c.org/ns/1.0", "location")} {
      attribute {"type"} {"gps"}, (: NOTE: subtype attributes for preferred and alternative are added as a separate processing step before applying updates :)
      $sourceAttr,
      element {QName("http://www.tei-c.org/ns/1.0", "geo")} {$contents}
    }
    default return ()
};