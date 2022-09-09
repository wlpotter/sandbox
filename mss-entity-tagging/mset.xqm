xquery version "3.1";

(:
: Module Name: Manuscript Entity Tagging
: Module Version: 1.0
: Copyright: GNU General Public License v3.0
: Proprietary XQuery Extensions Used: None
: XQuery Specification: 08 April 2014
: Module Overview: This module contains functions for generating a csv report
:                  of tagged entities in a given TEI XML manuscript database.
:                  It was originally developed for Syriaca.org's Digital Catalogue
:                  of Syriac Manuscripts in the British Library.
:)

(:~ 
: This module provides the functions that generate a CSV report of tagged entities
: (authors, works, persons, places, and bibliography) in a database of manuscript
: catalogue entries.
:
: @author William L. Potter
: @version 1.0
:)
module namespace mset="http://wlpotter.github.io/ns/mset";
import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $mset:current-dateTime := current-dateTime();

declare function mset:generate-tagged-entity-report($manuscripts as node()+, $entity-target as xs:string){
  let $adminMetadata := (
    element {"status"} {"pending"},
    element {"asignee"} {},
    element {"syriaca_notes"} {}
  )
  for $ms in $manuscripts
  let $recordFileLocation := element {"ms_record_file_location"} {substring-after(document-uri($ms), "britishLibrary-data")}
  let $msUri := element {"ms_level_uri"} {$ms//msDesc/msIdentifier/idno[@type="URI"]/text()}
  return
    for $msItem in $ms//msDesc//msItem (: currently just implementing for author and title, need a flag to control if we include checking within children :)
    (: xml:id, lookarounds, msPart/msDesc shelfmark and vol:p, and the msItem info like rubric, etc. :)
    let $msItemData := mset:get-msItem-data($msItem, $entity-target) (:xml:id author, title, rubric, etc.:)
    let $relatedMsItemData := mset:get-related-msItem-data($msItem, $msItem/parent::msItem) (:data for parent, child, siblings as needed :)
    let $wrightCatalogueInfo := mset:get-wright-catalogue-info($msItem/ancestor::msContents/parent::*)(: shelfmark + fol., vol:p for the catalogue entry :)
    
    for $entity in $msItem/*[name() = $entity-target]
    where $entity/node()
    let $entityData := mset:get-entity-data($entity)
    return
    <entity>
      {
        $recordFileLocation, $msUri, $entityData, $msItemData, $adminMetadata, $wrightCatalogueInfo, $relatedMsItemData, element {"timestamp"} {$mset:current-dateTime}
      }
    </entity>
};

declare function mset:get-entity-data($entity as node())
{
  let $uniqueXpath := functx:path-to-node-with-pos($entity)
  let $entityPositionInSequence := if(ends-with($uniqueXpath, "]")) then substring-before(functx:substring-after-last($uniqueXpath, "["), "]") else 1(: the numerical value in the sequence of siblings with the same name (e.g., if there are multiple authors) :)
  
  let $entityText := $entity//text()
  let $entityText := string-join($entityText, "")
  let $entityText := normalize-space($entityText)
  
  let $entityUriCurrent := $entity/@ref/string() (: works for all but tei:ref (for nested titles) and tei:bibl (which are a mess...) :)
  
  (: for titles include the @type attribute and a potential column to change it. If author include the @role :)
  let $entityTypeOrRole :=
    if (name($entity) = "author") then
      (element {"author_role_current"} {$entity/@role/string()}, 
       element {"author_role_corrected"} {})
    else if (name($entity) = "title") then
      (element {"title_type_current"} {$entity/@type/string()},
       element {"title_type_corrected"} {}) else()
  return (
      element {"unique_xpath"} {$uniqueXpath},
      element {name($entity)||"_position_in_sequence"} {$entityPositionInSequence},
      element {name($entity)||"_text_node"} {$entityText},
      element {name($entity)||"_uri_current"} {$entityUriCurrent},
      element {name($entity)||"_uri_possibility1"} {},
      element {name($entity)||"_uri_possibility2"} {},
      element {name($entity)||"_uri_corrected"} {},
      $entityTypeOrRole
    )
};

declare function mset:get-msItem-data($msItem as node(), $entity-target as xs:string)
{
  let $msItemId := element {"msItem_xml-id"} {$msItem/@xml:id/string()}
  let $startingLocus := element {"locus_start"} {$msItem/locus/@from/string()}
  let $authorTextNode := for $author in $msItem/author return normalize-space(string-join($author//text(), " "))
  let $authorTextNode := string-join($authorTextNode, "|") 
  let $authorTextNode := if($entity-target != "author") then element {"author_text_node"} {$authorTextNode} else()
  
  let $titleTextNode := for $title in $msItem/title return normalize-space(string-join($title//text(), " "))
  let $titleTextNode := string-join($titleTextNode, "|") 
  let $titleTextNode := if($entity-target != "title") then element {"title_text_node"} {$titleTextNode} else()
  
  let $rubric := element {"rubric"} {normalize-space(string-join($msItem/rubric/text(), " "))}
  let $incipit := element {"incipit"} {normalize-space(string-join($msItem/incipit/text(), " "))}
  let $explicit := element {"explicit"} {normalize-space(string-join($msItem/explicit/text(), " "))}
  let $finalRubric := element {"finalRubric"} {normalize-space(string-join($msItem/finalRubric/text(), " "))}
  
  return ($msItemId, $startingLocus, $authorTextNode, $titleTextNode, $rubric, $incipit, $explicit, $finalRubric)
  (:include notes??:)
};

declare function mset:get-wright-catalogue-info($codicologicalUnit as node())
{
  let $wrightCatLocation := $codicologicalUnit/additional/listBibl/bibl/citedRange[@unit="pp"]/text()
  let $wrightCatLocation := element {"wright_catalogue_location"} {$wrightCatLocation}

  let $wrightEntry := $codicologicalUnit/additional/listBibl/bibl/citedRange[@unit="entry"]/text()
  let $wrightEntry := element {"wright_entry_roman_numeral"} {$wrightEntry}
  
  let $shelfmark := element{"shelf_mark"} {$codicologicalUnit/msIdentifier/altIdentifier/idno[@type="BL-Shelfmark"]/text()}
  
  return($wrightCatLocation, $wrightEntry, $shelfmark)
};

declare function mset:get-related-msItem-data($msItem, $parent) {
  let $parentData := mset:create-item-string($parent)
  let $parentData := element {"parent_item"} {$parentData}
  
  let $msItemIndex := functx:path-to-node-with-pos($msItem)
  let $msItemIndex := if(ends-with($msItemIndex, "]")) then xs:integer(substring-before(functx:substring-after-last($msItemIndex, "["), "]")) else 1
  let $siblingData := 
    for $sibling at $i in $parent/msItem
    return 
      if($i = ($msItemIndex - 1)) then element {"preceding_sibling_item"} {mset:create-item-string($sibling)}
      else if($i = ($msItemIndex +1)) then element {"following_sibling_item"} {mset:create-item-string($sibling)}
      else ()
  (: the following two lines ensure that empty columns are created if there are no matching sibling elements, so the csv works properly :)
  let $precedingSiblingData := if ($siblingData/preceding_sibling_item) then $siblingData/preceding_sibling_item else element {"preceding_sibling_item"}  {}
  let $followingSiblingData := if ($siblingData/following_sibling_item) then $siblingData/following_sibling_item else element {"following_sibling_item"}  {}

  let $firstChildData := mset:create-item-string($msItem/msItem[1])
  let $firstChildData := element {"first_child_item"} {$firstChildData}
  return ($parentData, $siblingData, $firstChildData)
};

declare function mset:create-item-string($msItem as node()?)
as xs:string?
{
  if (not(empty($msItem))) then
  let $authorString := 
    for $author in $msItem/author
    return normalize-space(string-join($author//text(), " "))
  let $authorString := if($authorString != "") then string-join($authorString, ", ") else ()
  
  let $englishTitle := normalize-space(string-join($msItem/title[1]//text(), " "))
  let $otherTitles := 
    for $title in $msItem/title[position() > 1]
    return normalize-space(string-join($title//text(), " "))
  let $otherTitles := if ($otherTitles != "") then " ("||string-join($otherTitles, "; ")||")" else ()
  let $titleString := '"'||$englishTitle||'"'||$otherTitles
  
  let $folioString := "Foll. "||string-join($msItem/locus/@from/string(), ", ")||"-"||string-join($msItem/locus/@to/string(), ", ")
  
  return string-join(($authorString, $titleString, $folioString), ". ")
  
 else()
  (: return of the form `Author, Author. "First English Title" (Other titles in any language; other titles). Foll. xb-ya`:)
};
(:
- get the identifier data of an entity tag (ms uri, msPart uri, msItem xml:id, unique xpath, item location in an xpath sequence)
- get the entity information (the text node, current uri, create place holders for the possible and corrected uris)
- get non-entity msItem information (author, title, rubric, etc.)
- get Wright catalogue info for the msItem (shelfmark and folio, vol and page of the containing entry)
- get surrounding msItem info
- add the admin metadata fields
- return as csv (or as xml and let the driver return as csv?)

- later: get the information for entities that aren't the author and title (e.g., persNames in notes)
  - entity's element name
  - the containing element name (and/or the xpath back up to the containing msItem)
  - element text
- later: get info for additions as well as msItems
:)

(:
authors and titles

- loop through the ms records
  - get the file path (relative to the britishLibrary-data repo)
  - get the ms level URI
- loop through any msParts if they exist
  - get the msPart URI
- loop through the msItems within the parts or within the msDesc if no parts (need this distinction?)
  - get the msItem xml:id
  - for each /msItem/author (or title if titles) get the unique xpath  to that element as well as the item-in-sequence value of that item, i.e. is it the first or second author
  - get the text node (with //text() and string-join) of that element
  - get the author uri if it exists
  - create empty columns for author uri possibility/ies (maybe 2-3?)
  - create empty column for corrected uri
  - get the other msItem info: title/author (whichever you are not targeting for tagging), "|"-join multiples as needed
    - author or title
    - rubric
    - incipit
    - quote
    - explicit
    - finalRubric
    - note(s)
- get surrounding msItem info, of the form `Author, Author, "First English Title" ("Any other titles, including Syriac, Latin, etc."). Foll. x-y"` for the following, if they exist:
  - parent
  - first child
  - last child? (if more than one?)
  - preceding sibling 
  - following sibling
- get the Wright info from the msPart or msDesc containing the msContents -> store this in a variable before the msItem loop for easy reference
  - shelfmark
  - item folio (this is from the msItem)
  - vol:pages
- add columns for admin/process metadata
  - status (default = "pending")
  - asignee (default is empty)
  - Syriaca_notes (default is empty)
:)

(:
: INGEST URI DATA FROM CSV
:)

(: the following functions ingest data from a spreadsheet created by the above functions whose URIs have been filled in :)

declare function mset:parse-csv($csvUri as xs:string)
as node()
{
    let $f := file:read-text($csvUri)
  return csv:parse($f, map{"header": "yes"})
};

(:
given a document, find all the relevant data rows from the csv data
:)
declare function mset:get-entity-rows-by-manuscript-uri($msUri as xs:string, $data as node())
as node()*
{
  for $row in $data/*:csv/*:record
  where $row/*:ms_level_uri/text() = $msUri
  return $row
};

(:
given a row of data, update the entity with the matched URI
:)
declare %updating function mset:update-entity-uri($doc as node(), $row as node())
{
  let $target := mset:dynamic-path($doc, $row/*:unique_xpath/text())
  (: let $target := $target[$row/*:author_position_in_sequence/text()] :)
  let $target := 
    if(count($target) > 1) then 
      for $t at $i in $target
      where $i = xs:integer($row/*:author_position_in_sequence/text())
      return $t
    else $target
  let $uri := $row/*:author_uri_possibility1/text()
  return 
    if($uri != "") then 
      if($target/@ref) then 
        replace value of node $target/@ref with $uri
      else
        insert node attribute {"ref"} {$uri} into $target
  else delete node $target/@ref
};

declare function mset:dynamic-path
  ( $parent as node() ,
    $path as xs:string )  as item()* {

  let $nextStep := functx:substring-before-if-contains($path,'/')
  let $predicate := substring-after($nextStep, '[')
  let $predicate := substring-before($predicate, ']')
  let $nextStep := functx:substring-before-if-contains($nextStep, '[')
  
  let $restOfSteps := substring-after($path,'/')
  for $child at $i in
    ($parent/*[functx:name-test(name(),$nextStep)],
     $parent/@*[functx:name-test(name(),
                              substring-after($nextStep,'@'))])
  let $isMatch := ($predicate = "" or xs:integer($predicate) = $i)
  
  return if ($isMatch) then 
           if ($restOfSteps)
           then mset:dynamic-path($child, $restOfSteps)
           else $child
         else ()
 } ;
(:
- get relevant data based on ms uri
- get entity sequence by xpath (use a local copy of the parse dynamic xpaths function) column
- get the entity based on position in sequence column
- replace/create author URI with the value from ____ column
- replace node with the updated node
:)