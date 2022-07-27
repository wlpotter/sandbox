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
: Given a sequence of strings that derive from the Wright Taxonomy CV, return a list element
: Each item should
: WAITING on a decision about if we need to use a listRelation or just a list
:)
declare function mshead:create-wright-taxonomy-list-from-sequence($sequence as xs:string*)
as node()
{
  
};
(:

- notes about description incomplete, data model incomplete, etc. (WAITING to see if this is going in the head)
- if self is an msPart or has child msParts (WAITING to discuss)
  - label for type of part
  - summary notes (for the composite) with the number of child parts
  - listRelation(s) for the part URIs?
:)
