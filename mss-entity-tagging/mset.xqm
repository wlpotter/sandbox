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
    let $relatedMsItemData := "" (:data for parent, child, siblings as needed :)
    let $wrightCatalogueInfo := "" (: shelfmark + fol., vol:p for the catalogue entry :)
    
    for $entity in $msItem/*[name() = $entity-target]
    (: maybe filter for non-empty entity elements? :)
    let $entityData := mset:get-entity-data($entity)
    return
    <entity>
      {
        $recordFileLocation, $msUri, $entityData, $msItemData, $adminMetadata
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
  
  return (
      element {"unique_xpath"} {$uniqueXpath},
      element {name($entity)||"_position_in_sequence"} {$entityPositionInSequence},
      element {name($entity)||"_text_node"} {$entityText},
      element {name($entity)||"_uri_current"} {$entityUriCurrent},
      element {name($entity)||"_uri_possibility1"} {},
      element {name($entity)||"_uri_possibility2"} {},
      element {name($entity)||"_uri_corrected"} {}
    )
};

declare function mset:get-msItem-data($msItem as node(), $entity-target as xs:string)
{
  let $msItemId := element {"msItem_xml-id"} {$msItem/@xml:id/string()}
  let $authorTextNode := for $author in $msItem/author return normalize-space(string-join($author//text(), " "))
  let $authorTextNode := string-join($authorTextNode, "|") 
  let $authorTextNode := if($entity-target != "author") then element {"author_text_node"} {$authorTextNode}
  
  let $titleTextNode := for $title in $msItem/title return normalize-space(string-join($title//text(), " "))
  let $titleTextNode := string-join($titleTextNode, "|") 
  let $titleTextNode := if($entity-target != "title") then element {"title_text_node"} {$titleTextNode}
  
  let $rubric := element {"rubric"} {normalize-space(string-join($msItem/rubric/text(), " "))}
  let $incipit := element {"incipit"} {normalize-space(string-join($msItem/incipit/text(), " "))}
  let $explicit := element {"explicit"} {normalize-space(string-join($msItem/explicit/text(), " "))}
  let $finalRubric := element {"finalRubric"} {normalize-space(string-join($msItem/finalRubric/text(), " "))}
  
  return ($msItemId, $authorTextNode, $titleTextNode, $rubric, $incipit, $explicit, $finalRubric)
  (:include notes??:)
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