xquery version "3.1";

(:
: Module Name: Manuscript Description Heading Generation
: Module Version: 1.0
: Copyright: GNU General Public License v3.0
: Proprietary XQuery Extensions Used: None
: XQuery Specification: 08 April 2014
: Module Overview: This module contains functions for batch creation of the tei:head
:                  element for manuscript records. This module merely creates the element.
:                  This allows the module to be used both in the post-processing
:                  pipeline and with a standalone update driver
:)

(:~ 
: This module provides the functions that create a tei:head element for ms
: descriptions.
:
: @author William L. Potter
: @version 1.0
:)

module namespace mshead="http://srophe.org/srophe/mshead";

import module namespace functx="http://www.functx.com";


declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $mshead:taxonomy-relation-name := "dcterms:type";

declare variable $mshead:taxonomy-relation-ref := "http://purl.org/dc/terms/type";

declare variable $mshead:whole-to-part-name :=
  map {
    "generic": "syriaca:has-unspecified-codicological-part",
    "pUpper": "syriaca:has-palimpsest-upper",
    "pLower": "syriaca:has-palimpsest-lower",
    "flyleaf": "syriaca:has-flyleaf"
  };
  
declare variable $mshead:whole-to-part-ref :=
  map {
    "generic": "syriaca:has-unspecified-codicological-part",
    "pUpper": "syriaca:has-palimpsest-upper",
    "pLower": "syriaca:has-palimpsest-lower",
    "flyleaf": "syriaca:has-flyleaf"
  };
  
declare variable $mshead:part-to-whole-name :=
  map {
    "generic": "syriaca:is-unspecified-codicological-part-of",
    "pUpper": "syriaca:is-palimpsest-upper-of",
    "pLower": "syriaca:is-palimpsest-lower-of",
    "flyleaf": "syriaca:is-flyleaf-of"
  };
  
declare variable $mshead:part-to-whole-ref :=
  map {
    "generic": "syriaca:is-unspecified-codicological-part-of",
    "pUpper": "syriaca:is-palimpsest-upper-of",
    "pLower": "syriaca:is-palimpsest-lower-of",
    "flyleaf": "syriaca:is-flyleaf-of"
  };
  
declare variable $mshead:part-and-desc-ana :=
  map {
    "generic-composite": "syriaca-composite-manuscript",
    "palimpsest-composite": "syriaca-palimpsested-manuscript",
    "palimpsest-upper": "syriaca-palimpsest-upper",
    "palimpsest-lower": "syriaca-palimpsest-lower",
    "flyleaf": "syriaca-flyleaf"    
  };

declare variable $mshead:wright-taxonomy-node :=
<taxonomy xml:id="Wright-BL-Taxonomy" xmlns="http://www.tei-c.org/ns/1.0">
          <category xml:id="biblical-manuscripts">
            <category xml:id="bible-ot"><catDesc>Old Testament</catDesc></category>
            <category xml:id="bible-nt"><catDesc>New Testament</catDesc></category>
            <category xml:id="bible-apocrypha"><catDesc>Apocrypha</catDesc></category>
            <category xml:id="bible-punctuation"><catDesc>Punctuation</catDesc></category>
          </category>
          <category xml:id="service-books">
            <category xml:id="psalter"><catDesc>Psalters</catDesc></category>
            <category xml:id="lectionaries"><catDesc>Lectionaries</catDesc></category>
            <category xml:id="missals"><catDesc>Missals</catDesc></category>
            <category xml:id="sacerdotals"><catDesc>Sacerdotals</catDesc></category>
            <category xml:id="choral"><catDesc>Choral Books</catDesc></category>
            <category xml:id="hymns"><catDesc>Hymns</catDesc></category>
            <category xml:id="prayers"><catDesc>Prayers</catDesc></category>
            <category xml:id="funerals"><catDesc>Funeral Services</catDesc></category>
          </category>
          <category xml:id="theology">
            <category xml:id="theo-single"><catDesc>Individual Authors</catDesc></category>
            <category xml:id="theo-collected"><catDesc>Collected Authors</catDesc></category>
            <category xml:id="theo-catenae"><catDesc>Catenae Patrum and Demonstrations against Heresies</catDesc></category>
            <category xml:id="theo-anonymous"><catDesc>Anonymous Works</catDesc></category>
            <category xml:id="theo-council"><catDesc>Councils of the Church and Ecclesiastical Canons</catDesc></category>
          </category>
          <category xml:id="wright-history">
            <category xml:id="history"><catDesc>History</catDesc></category>
          </category>
          <category xml:id="lives">
            <category xml:id="lives-collect"><catDesc>Collected Lives</catDesc></category>
            <category xml:id="lives-single"><catDesc>Single Lives</catDesc></category>
          </category>
          <category xml:id="scientific-lit">
            <category xml:id="sci-logic"><catDesc>Logic and Rhetoric</catDesc></category>
            <category xml:id="sci-grammar"><catDesc>Grammar and Lexicography</catDesc></category>
            <category xml:id="sci-ethics"><catDesc>Ethics</catDesc></category>
            <category xml:id="sci-medicine"><catDesc>Medicine</catDesc></category>
            <category xml:id="sci-agriculture"><catDesc>Agriculture</catDesc></category>
            <category xml:id="sci-chemistry"><catDesc>Chemistry</catDesc></category>
            <category xml:id="sci-natural-history"><catDesc>Natural History</catDesc></category>
          </category>
          <category xml:id="wright-fly-leaves">
            <category xml:id="fly-leaves"><catDesc>Fly Leaves</catDesc></category>
          </category>
          <category xml:id="appendices">
            <category xml:id="appendix-a"><catDesc>Appendix A</catDesc></category>
            <category xml:id="appendix-b"><catDesc>Appendix B</catDesc></category>
          </category>
        </taxonomy>;
        
declare variable $mshead:manuscript-division-standard-note := 
  "The division of the manuscript into codicological units, catalogued as &lt;msPart/&gt; elements, has been adapted from Wright.";
        
declare function mshead:compose-head-element($msDesc as node())
as node()
{
  let $contentsNote := mshead:generate-contents-note($msDesc)
  let $taxonomyList := mshead:get-wright-taxonomy-value-from-profileDesc($msDesc)
  let $taxonomyListRelation := mshead:create-wright-taxonomy-list-from-sequence($taxonomyList, $msDesc/msIdentifier/idno/text())
  let $wholeToPartListRelation := mshead:create-composite-to-part-listRelation($msDesc)
  let $partToWholeListRelation := mshead:create-part-to-composite-listRelation($msDesc)
  return element Q{'http://www.tei-c.org/ns/1.0'}head {
    $contentsNote,
    $taxonomyListRelation,
    $wholeToPartListRelation,
    $partToWholeListRelation,
    if(mshead:needs-manuscript-division-note($msDesc)) then mshead:create-manuscript-division-note(())
  }
};

(:
: Given an msDesc or msPart,
: Create a contents summary note.
: USe the first five top level msItem elements, concatenate their title and author elements.
: If more than five, add 'etc.'
: Separate with a semicolon
: A second sentence should be included that says 'In total, including sub-sections, \d+ items have been identified'. indicating the total number of msItems
: A third sentence should let the reader know that the editors have renumbered items, so they may not reflect Wright's original numeration.
: 
: if a part does not contain any items (it is likely a composite container), note that it does not contain items and direct the reader to the sub-parts
:)
declare function mshead:generate-contents-note($msSection as node())
as node()
{
  let $totalItemCount := count($msSection/msContents//msItem)
  return if($totalItemCount = 0) then
    element{QName("http://www.tei-c.org/ns/1.0", "note")} 
    {attribute {"type"} {"contents-note"},
    "This manuscript record does not have associated contents as it is likely a composite manuscript. See the corresonding parts for a listing of its contents."}
  else
    let $firstFiveTopLevelMsItems := $msSection/msContents/msItem[position() <= 5]
    let $hasMoreThanFiveTopLevelItems := boolean(count($msSection/msContents/msItem) > 5)
    let $contentsSummary := mshead:generate-contents-summary($firstFiveTopLevelMsItems, $hasMoreThanFiveTopLevelItems)
    
    let $itemCountNote := "In total, including sub-sections, this manuscript contains "||$totalItemCount|| " items."
    let $renumberNotaBene := "N.B., items have been renumbered by the editors and may not reflect Wright's original numeration."
    return element {QName("http://www.tei-c.org/ns/1.0", "note")} 
          {attribute {"type"} {"contents-note"}, 
           string-join(($contentsSummary, $itemCountNote, $renumberNotaBene), " ")}
};

declare function mshead:generate-contents-summary($topLevelContents as node()*, $isContentsAbbreviated as xs:boolean)
as xs:string
{
  let $endTag := if($isContentsAbbreviated) then " ; ..."
  let $contents :=
    for $item in $topLevelContents
    (: later enhancement -- use a lookup of the work record if URI given :)
    let $author := 
      for $author in $item/author
      return if($author/text() != "") then normalize-space(string-join($author//text(), " "))
    let $author := string-join($author, ", ")
    let $author := normalize-space($author)
    let $title := $item/title[1]//text()
    let $title := string-join($title, "")
    let $title := normalize-space($title)
    return if($author != "") then string-join(($author, $title), ". ") else $title
 let $contents := string-join($contents, " ; ")
 let $endPeriod := if (ends-with($contents, ".")) then () else "."
 return "This manuscript contains: "||$contents||$endTag||$endPeriod
};

(:
: Given an msDesc or msPart, return the corresponding wright taxonomy value(s)
: Navigate up the XML tree, and then back down to find the taxonomy list.
: If it is a part, then only get the matching one; otherwise return all of them.
: If multiple values encoded in the same ref element, they should be separated out into their own items
: The series of items will be used to encode them in the tei:head
:)
declare function mshead:get-wright-taxonomy-value-from-profileDesc($msDesc as node())
as xs:string*
{
  let $profileDesc := $msDesc/ancestor::teiHeader/profileDesc
  let $wrightTaxonomyItems := $profileDesc/textClass/keywords[@scheme="#Wright-BL-Taxonomy"]/list/item
  let $values := 
    if(name($msDesc) = "msDesc" and not($msDesc/msPart)) then 
      for $item in $wrightTaxonomyItems
      let $value := $item/ref/@target/string()
      let $value := tokenize($value, " ")
      let $value := for $val in $value return functx:substring-after-if-contains($val, "#")
      return $value
  (: for item in list of items, get any that don't have a part associated :)
    else
      let $partId := "#"||$msDesc/@xml:id/string()
      for $item in $wrightTaxonomyItems
      let $matchesPart := for $ref in $item/ref return if(functx:contains-word($ref/@target, $partId)) then true()
      where $matchesPart
      let $value := for $ref in $item/ref return if(not(functx:contains-word($ref/@target, $partId))) then $ref/@target/string()
      let $value := tokenize($value, " ")
      let $value := for $val in $value return functx:substring-after-if-contains($val, "#")
      return $value
   return $values
};

(:
: Given a sequence of strings that derive from the Wright Taxonomy CV, return a listRelation element
: Each item in the sequence should comprise a tei:relation, as follows:
: <relation name="dcterms:type" ref="http://purl.org/dc/terms/type" active="$MSSURI" passive="$keyword"/>
:)
declare function mshead:create-wright-taxonomy-list-from-sequence($sequence as xs:string*, $msUri as xs:string)
as node()
{
  let $relations :=
    for $kw in $sequence
    let $label := 
      for $l in $mshead:wright-taxonomy-node//category
      where functx:substring-after-if-contains($kw, "#") = $l/@xml:id/string()
      return $l/catDesc/text()
    let $label := element {QName("http://www.tei-c.org/ns/1.0", "desc")} {$label}
    return element {QName("http://www.tei-c.org/ns/1.0", "relation")} 
            {
              attribute {"name"} {$mshead:taxonomy-relation-name},
              attribute {"ref"} {$mshead:taxonomy-relation-ref},
              attribute {"active"} {$msUri},
              attribute {"passive"} {"#"||$kw},
              $label
            }
  return element {QName("http://www.tei-c.org/ns/1.0", "listRelation")} {attribute {"type"} {"Wright-BL-Taxonomy"}, $relations}
};

(:
: Takes an msDesc (or msPart) and returns a listRelation that connects the composite to the part URIs
: NOTE, currently only parsing direct descendants. Multi-level composites will need to have this run on each of the parts
:)
declare function mshead:create-composite-to-part-listRelation($msDesc as node())
as node()?
{
  if ($msDesc/msPart) then 
    let $numberOfParts := count($msDesc/msPart)
    let $msUri := $msDesc/msIdentifier/idno/text()
    let $desc := element Q{'http://www.tei-c.org/ns/1.0'}desc {"This composite manuscript consists of "||$numberOfParts||" distinct parts:"}
    let $msPartData := 
      for $part in $msDesc/msPart
      let $uri := $part/msIdentifier/idno/text()
      let $shelfmark := $part/msIdentifier/altIdentifier/idno[@type="BL-Shelfmark"]/text()(: NOTE: after we batch clean up the shelfmarks, we can pull the part that is distinct from the whole shelfmark :)
      return map {"uri": $uri, "shelfmark": $shelfmark}
    let $relations :=
      for $part in $msPartData
      let $partDesc := element Q{'http://www.tei-c.org/ns/1.0'}desc {$part?shelfmark}
      let $relationType := 
        if(contains($part?shelfmark, "upper")) then "pUpper"
        else if (contains($part?shelfmark, "lower")) then "pLower"
        else "generic"
      let $relationRef := map:get($mshead:whole-to-part-ref, $relationType)
      let $relationName := map:get($mshead:whole-to-part-name, $relationType)
      return element Q{'http://www.tei-c.org/ns/1.0'}relation {
        attribute {"name"} {$relationName},
        attribute {"ref"} {"#"||$relationRef},
        attribute {"active"} {$msUri},
        attribute {"passive"} {$part?uri},
        $partDesc
      }
    return element Q{'http://www.tei-c.org/ns/1.0'}listRelation {attribute {"type"} {"composite-to-parts"}, $desc, $relations}
  else ()
};

declare function mshead:create-part-to-composite-listRelation($msPart as node())
as node()?
{
  if($msPart/parent::msDesc or $msPart/parent::msPart) then
    let $desc := element Q{'http://www.tei-c.org/ns/1.0'}desc {"This unit is a part of a composite manuscript:"}
    let $uri := $msPart/msIdentifier/idno/text()
    let $compositeUri := $msPart/parent::*/msIdentifier/idno/text()
    let $compositeShelfmark := $msPart/parent::*/msIdentifier/altIdentifer/idno[@type="BL-Shelfmark"]/text()
    let $shelfmark := $msPart/msIdentifier/altIdentifer/idno[@type="BL-Shelfmark"]/text()
    let $relationType := 
        if(contains($shelfmark, "upper")) then "pUpper"
        else if (contains($shelfmark, "lower")) then "pLower"
        else "generic"
    let $relation := element Q{'http://www.tei-c.org/ns/1.0'}relation {
        attribute {"name"} {map:get($mshead:part-to-whole-name, $relationType)},
        attribute {"ref"} {"#"||map:get($mshead:part-to-whole-ref, $relationType)},
        attribute {"active"} {$uri},
        attribute {"passive"} {$compositeUri},
        element Q{'http://www.tei-c.org/ns/1.0'}relation {$compositeShelfmark}
      }
    return element Q{'http://www.tei-c.org/ns/1.0'}listRelation {
        attribute {"type"} {"part-to-composite"},
        $desc,
        $relation
    }
  else ()
};

declare function mshead:needs-manuscript-division-note($msDesc as node())
as xs:boolean
{
  let $currentWrightEntry := $msDesc/msIdentifier/altIdentifier/idno[@type="Wright-BL-Roman"]/text()
  let $childMatches :=
    for $part in $msDesc//msPart
    let $partWrightEntry := $part/msIdentifier/altIdentifier/idno[@type="Wright-BL-Roman"]/text()
    return if($currentWrightEntry = $partWrightEntry) then $partWrightEntry
  return ($currentWrightEntry = $msDesc/parent::*/msIdentifier/altIdentifier/idno[@type="Wright-BL-Roman"]/text() or count($childMatches) > 0)
};

declare function mshead:create-manuscript-division-note($extraProse as xs:string?)
as node()
{
  element Q{'http://www.tei-c.org/ns/1.0'}note {
    attribute {"type"} {"manuscript-division"},
    normalize-space(string-join(($mshead:manuscript-division-standard-note, $extraProse), " "))
}
};