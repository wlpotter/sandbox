xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $path-to-repo := "/home/arren/Documents/GitHub/britishLibrary-data/";
declare variable $input-collection := collection($path-to-repo||"data/tei/");

declare function local:get-persNames-from-creator($creator, $lang) {
  let $names :=
    (: collect the descendant text of a name, including if there's placeNames or whatever :)
    for $name in $creator/persName
    return 
      (: if filtering by lang :)
      if($lang != "" and contains($name/@xml:lang/string(), $lang)) then $name//text() => string-join(" ") => normalize-space()
      (: if no lang is passed, just get the ones that don't have an xml:lang :)
      else if($lang = "" and not($name/@xml:lang)) then $name//text() => string-join(" ") => normalize-space()
      (: ignore any that don't match the criteria:)
      else()
    
  return string-join($names, " | ") (: return a pipe-separated string of the names :)
};

declare function local:get-titles-from-msItem($item) {
  (: return a joined string of the title's descendant text nodes, excluding footnotes :)
  for $title in $item/title
  let $textFrags :=
    for $node in $title//node()
    where $node/name() != "note"
    return $node/descendant-or-self::text()
  return string-join($textFrags, " ") => normalize-space()
};

declare function local:get-creator-node-info($creator, $nodeName) {
  let $enNames := local:get-persNames-from-creator($creator, "en")
  let $syrNames := local:get-persNames-from-creator($creator, "syr")
  let $otherNames := local:get-persNames-from-creator($creator, "")
  let $tempId := $creator/@ref/string() (: returns the ref, if there is one :)
  
  (: role, if an editor :)
  let $role := $creator/@role/string()
  
  let $msItemParent := $creator/parent::msItem
  let $itemId := $msItemParent/@xml:id/string()
  let $positionInSeq := functx:index-of-node($msItemParent/*[name() = $nodeName], $creator)
  
  let $msItemLocus := $msItemParent/locus/@from/string() => string-join("; ")
  let $msItemTitle := local:get-titles-from-msItem($msItemParent) => string-join(" | ")
  
  let $msDesc := $creator/ancestor::msDesc
  let $msLevelUri := $msDesc/msIdentifier/idno[@type="URI"]/text()
  
  (: the most enclosing msPart and associated info :)
  let $part := $msItemParent/ancestor::msPart[1]
  let $partId := $part/@xml:id/string()
  let $partUri := $part/msIdentifier/idno[@type="URI"]/text()
  
  (: get the bibl containing catalogue info from the part, or msDesc :)
  let $catalogueBibl := 
    if($part) then $part/additional/listBibl/bibl
    else $msDesc/additional/listBibl/bibl
  
  let $catalogueLoc := "vol. "|| $catalogueBibl/citedRange[@unit="vol"]/text() || ", p. " || $catalogueBibl/citedRange[@unit="p"]/text() || " ("||$catalogueBibl/citedRange[@unit="entry"]/text()||")"
  let $cataloguePdfUrl := $catalogueBibl/ref[@type="internet-archive-pdf"]/@target/string()
  
  (: turn into a csv row; include the node name as 'type' :)
  return
  <row>
    <msUri>{$msLevelUri}</msUri>
    <part>{$partId}</part>
    <partUri>{$partUri}</partUri>
    <tempID>{$tempId}</tempID>
    <type>{$nodeName}</type>
    <role>{$role}</role>
    <englishName>{$enNames}</englishName>
    <syriacName>{$syrNames}</syriacName>
    <noLangName>{$otherNames}</noLangName>
    <itemTitle>{$msItemTitle}</itemTitle>
    <itemStartLocus>{"fol. "||$msItemLocus }</itemStartLocus>
    <catalogueLoc>{$catalogueLoc}</catalogueLoc>
    <catalogueUrl>{$cataloguePdfUrl}</catalogueUrl>
    <msItemId>{$itemId}</msItemId>
    <nodePosition>{$positionInSeq}</nodePosition>
  </row>
};

let $rows :=
  for $creator in $input-collection//msContents//msItem/*[name() = "author" or name() = "editor"]
  where not($creator/@ref) or contains($creator/@ref, "smblPers")
  
  return local:get-creator-node-info($creator, $creator/name())

return <csv>{$rows}</csv> => csv:serialize(map {"header": "yes"})