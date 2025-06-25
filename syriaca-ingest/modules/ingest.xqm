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
    ingest:ingest-series-of-elements($item?place_names, $matchedDoc//place/placeName, "place_name", $docId, $biblIdOffset),
    ingest:ingest-series-of-elements($item?gps, $matchedDoc//place/location[@type="gps"], "gps", $docId, $biblIdOffset),
    insert node $newBibls after $matchedDoc//body//bibl[last()]
  )
  (:
  - data needing comparison: place name, gps, URIs
  - generic function to compare a set of data against an existing path
    - it should take an optional list of sources, a path to the data in the existing record, and an element name (all should be updating functions)
    - the element name should be used to determine on a switch if it's just comparing the descendant text nodes (e.g., person or place name can be treated the same) or if it needs to look more closely
    - if it's a match, call a function to update the source attribute of the match
    - if it's not, call a function to create a new element based on the element name and then add it to the end of the list of that element
  :)

};

declare function ingest:create-new-bibls-with-ids($bibls, $idBase as xs:string, $offset as xs:integer? := 0){
  for $k in map:keys($bibls)(:bib4219-3:)
  let $bibId := "bib"||$idBase||"-"||$k+$offset
  let $bib := map:get($bibls, $k)
  
  return element {$bib/name()} {
    $bib/@*,
    attribute {"xml:id"} {$bibId},
    $bib/*
  }
};

declare %updating function ingest:ingest-series-of-elements($series as item()*, $toCompare as item()*, $elementType as xs:string, $docId as xs:string, $biblIdOffset as xs:integer? := 0) {
  for $item at $i in $series
  let $sourceString := 
    for $s in $item?sources
    return "#bib"||$docId||"-"||xs:string($s + $biblIdOffset)
  let $sourceString := string-join($sourceString, " ")
  let $options := {
    "item_index": $i,
    "count_of_to_compare": count($toCompare)
  }
  return
    ingest:ingest-element-data($item?value, $toCompare, $elementType, $docId, $sourceString, $options)
};

(:
Assumes you are comparing a single piece of data with a sequence of 0 or more elements
@param $toIngest is a piece of string data that is compared with the contents of @param $toCompare, which is a series of elements of that data type
@param $source is a string such as "#bib1234-1 #bib1234-2" used to create or update the source attribute for the data; by default it is blank
@param $elementType is used to determine whether a simple string comparison is sufficient or if more robust comparisons are required, and to control the elements created from $toIngest
@param $options is a map of information used in certain cases, such as to control when to use subtype=preferred/alternate for gps locations
:)

declare %updating function ingest:ingest-element-data($toIngest as xs:string, $toCompare as element()*, $elementType as xs:string, $docId as xs:string, $source as xs:string := "", $options as map(*)? := {})
{
    (: TBD: when needed, implement a switch statement for cases where an element type needs a comparison different than "normalize all descendant text nodes", which works for gps and place/person names so far :)
    switch($elementType)
    case "gps" return ingest:ingest-gps-data($toIngest, $toCompare, $elementType, $docId, $source, $options)
    default return
     let $matches :=
       for $el in $toCompare
       where $el//text() => string-join(" ") => normalize-space() = $toIngest
       return {
         "original_node": $el,
         "updated_node": ingest:update-element-source-attribute($el, $source),
         "abs_path": functx:path-to-node-with-pos($el)
       }
  
    return 
      if (count($matches) > 0) then 
        for $m in $matches
        return replace node $m?original_node with $m?updated_node
      else 
        let $offset := ingest:get-id-offset($toCompare)
        let $newElement := ingest:create-new-element($toIngest, $elementType, $source, $docId, 1+$offset)
        return insert node $newElement after $toCompare[last()]
};

declare %updating function ingest:ingest-gps-data($toIngest as xs:string, $toCompare as element()*, $elementType as xs:string, $docId as xs:string, $source as xs:string := "", $options as map(*)? := {})
{
  let $existingLocs :=
       for $el at $i in $toCompare
       (: where $el//text() => string-join(" ") => normalize-space() = $toIngest :)
       
       let $elNewSource := 
         if ($el//text() => string-join(" ") => normalize-space() = $toIngest) then
           ingest:update-element-source-attribute($el, $source)
         else $el
       (:
       {
    "item_index": $i,
    "count_of_to_compare": count($toCompare)
  }
       :)
       let $updatedNode := ingest:update-gps-subtype($elNewSource, $i, $options?count_of_to_compare, $options?item_index)
       return {
         "original_node": $el,
         "updated_node": $updatedNode,
         "abs_path": functx:path-to-node-with-pos($el)
       }
    
    return (: ADD A BOOL TO ONLY UPDATE EXISTING IF THE ITEM INDEX IN OPTIONS IS 1 SO THAT YOU ONLY UPDATE THOSE ONCE :)
      if (count($existingLocs) > 0) then 
        for $loc in $existingLocs
        return replace node $loc?original_node with $loc?updated_node
      else 
        let $offset := ingest:get-id-offset($toCompare)
        let $newElement := ingest:create-new-element($toIngest, $elementType, $source, $docId, 1+$offset)
        return insert node $newElement after $toCompare[last()]
};

(: TBD: need to handle case where the source to append is empty, will want to add or keep the resp string... :)
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

declare function ingest:update-gps-subtype($element as item(), $elementPosition as xs:integer, $sizeOfSequence as xs:integer, $countOfNewData as xs:integer)
as item() {
  
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
    case "place_name" return element {QName("http://www.tei-c.org/ns/1.0", "placeName")} {
      attribute {"xml:id"} {"name"||$docId||"-"||$idSeq},
      attribute {"xml:lang"} {"en"}, (:TBD: defaults to English; should be able to override :)
      $sourceAttr,
      $contents
    }
    case "gps" return element {QName("http://www.tei-c.org/ns/1.0", "location")} {
      attribute {"type"} {"gps"}, (: TBD: add subtype handling...(maybe a passed map of options?:)
      $sourceAttr,
      element {QName("http://www.tei-c.org/ns/1.0", "geo")} {$contents}
    }
    default return ()
};