xquery version "3.1";

module namespace ingest="http://wlpotter.github.io/ns/syriaca-ingest/ingest";
import module namespace functx = "http://www.functx.com" at "https://www.datypic.com/xq/functx-1.0.1-doc.xq";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare function ingest:update-existing-records-with-new-data($existing-data as item()+, $data-to-ingest as item()+, $entity-type as xs:string) {
  
  for $item in $data-to-ingest?*
  let $matchedDoc := $existing-data[TEI/teiHeader/fileDesc/publicationStmt/idno[@type="URI"]/text() = $item?uri||"/tei"]
  let $docId := $item?uri => functx:substring-after-last("/")
  
  let $biblIdOffset := max(
      for $bibl in $matchedDoc//body//bibl
      return $bibl/@xml:id/string() => substring-after("-") => xs:integer()
    )
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