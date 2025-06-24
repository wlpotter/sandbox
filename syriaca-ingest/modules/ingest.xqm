xquery version "3.1";

module namespace ingest="http://wlpotter.github.io/ns/syriaca-ingest/ingest";
import module namespace functx = "http://www.functx.com" at "https://www.datypic.com/xq/functx-1.0.1-doc.xq";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare function ingest:update-existing-records-with-new-data($existing-data as item()+, $data-to-ingest as item()+, $entity-type as xs:string) {
  
  for $item in $data-to-ingest?*
  let $matchedDoc := $existing-data[TEI/teiHeader/fileDesc/publicationStmt/idno[@type="URI"]/text() = $item?uri||"/tei"]
  let $docId := $item?uri => functx:substring-after-last("/")
  
  let $biblIdOffset := ingest:get-id-offset($matchedDoc//body//bibl)
  
  let $ingestBibls := $item?bibls
  
  (: TBD: append to the list of existing bibls using xquery update :)
  let $newBibls := if(map:size($ingestBibls) > 0) then ingest:create-new-bibls-with-ids($ingestBibls, $docId, $biblIdOffset) else ()
  
  (:
  - data needing comparison: place name, gps, URIs
  - generic function to compare a set of data against an existing path
    - it should take an optional list of sources, a path to the data in the existing record, and an element name (all should be updating functions)
    - the element name should be used to determine on a switch if it's just comparing the descendant text nodes (e.g., person or place name can be treated the same) or if it needs to look more closely
    - if it's a match, call a function to update the source attribute of the match
    - if it's not, call a function to create a new element based on the element name and then add it to the end of the list of that element
  :)
  return $newBibls
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

(:
Assumes you are comparing a single piece of data with a sequence of 0 or more elements
@param $toIngest is a piece of string data that is compared with the contents of @param $toCompare, which is a series of elements of that data type
@param $source is a string such as "#bib1234-1 #bib1234-2" used to create or update the source attribute for the data; by default it is blank
@param $elementType is used to determine whether a simple string comparison is sufficient or if more robust comparisons are required, and to control the elements created from $toIngest
:)

declare %updating function ingest:ingest-element-data($toIngest as xs:string, $toCompare as element()*, $elementType as xs:string, $docId as xs:string, $source as xs:string := "")
{
   switch($elementType)
   case "gps" return () (: compare $toCompare/geo/string() :)
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

declare function ingest:update-element-source-attribute($element as element(), $sourceToAppend as xs:string)
as element()
 {
    if($element/@source) then 
      functx:add-or-update-attributes($element, QName("", "source"), string-join(($element/@source, $sourceToAppend), " "))
    else if ($element/@resp) then 
      functx:add-attributes(functx:remove-attributes($element, "resp"), QName("", "source"), $sourceToAppend)
    else 
      functx:add-attributes($element, QName("", "source"), $sourceToAppend)
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
    case "placeName" return element {QName("http://www.tei-c.org/ns/1.0", "placeName")} {
      attribute {"xml:id"} {"name"||$docId||"-"||$idSeq},
      attribute {"xml:lang"} {"en"}, (:TBD: defaults to English; should be able to override :)
      $sourceAttr,
      $contents
    }
    default return ()
};