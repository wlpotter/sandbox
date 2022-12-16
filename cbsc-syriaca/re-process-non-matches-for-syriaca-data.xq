(:
- get the union of Syriaca records
- go through each row and match on zotero uri or syriaca bibl uri
- get from the record the year, author stuff, and title stuff (if not already there)
- if possible get the styled citation
  - this if for all of them
:)

xquery version "3.1";


declare default element namespace "http://www.tei-c.org/ns/1.0";

import module namespace functx="http://www.functx.com";

declare variable $local:syriaca-zotero-group-id := "392292";

declare variable $local:input-csv := 
  let $pathToFile := "/home/arren/Documents/GitHub/sandbox/cbsc-syriaca/2022-12-09_syriaca-to-cbsc-possible-matches.csv"
  return csv:parse(file:read-text($pathToFile), map {"header": "yes"});
  
declare variable $local:syriaca-zotero-dump := 
  let $pathToColl := "/home/arren/Documents/syriaca-bibls/out"
  return collection($pathToColl);
  
declare variable $local:syriaca-exist-dump :=
  let $pathToColl := "/home/arren/Documents/syriaca-bibls/bibl/tei"
  return collection($pathToColl);
  
declare variable $local:cbsc-zotero-dump := 
  let $pathToDoc := "/home/arren/Documents/cbsc-bibls/cbsc-bibls_out_2022-11-18.xml"
  for $bibl in  doc($pathToDoc)/listBibl/biblStruct
  return $bibl;

declare variable $local:zotero-bibl-regex := "https?://w*\.?zotero\.org/groups/\d+/items/.+";

declare function local:get-bibl-date($bibl as node())
as xs:string?
{
  (: returns the date string, trying to parse for just the year if it is in ISO format, returning the full string otherwise :)
  let $date := $bibl//imprint/date
  let $date := $date[1] (: getting strange errors where positional parameters not working with xpath... but with sequences it seems to be fine?? :)
  return functx:substring-before-if-contains($date, "-")
};

declare function local:get-author-editor-string($bibl as node())
as xs:string?
{
  let $authorLevel := if($bibl/descendant-or-self::biblStruct/analytic) then $bibl/descendant-or-self::biblStruct/analytic else $bibl/descendant-or-self::biblStruct/monogr
  let $authorNames := 
    for $auth in $authorLevel/author
    order by $auth
    let $authName := if($auth//surname) then $auth//surname/text() else $auth//name/text()
    return if(count($authName) > 1) then string-join($authName, "/") else $authName
  let $editorLevel :=  if($bibl/descendant-or-self::biblStruct/analytic/editor) then $bibl/descendant-or-self::biblStruct/analytic else $bibl/descendant-or-self::biblStruct/monogr
  let $editorNames := 
    for $ed in $editorLevel/editor
    order by $ed
    let $edName :=  if($ed//surname) then $ed//surname/text() else $ed//name/text()
    return if(count($edName) > 1) then string-join($edName, "/")||" (ed.)" else $edName||" (ed.)"
    
  let $authorString := string-join($authorNames, ", ")
  let $editorString := string-join($editorNames, ", ")
  return $authorString||", "||$editorString
};

declare function local:get-bibl-title($bibl as node())
as xs:string?
{
    (: use the analytic level title if it exists, otherwise use the monograph level :)
    let $titleLevel := if($bibl/descendant-or-self::biblStruct/analytic) then $bibl/descendant-or-self::biblStruct/analytic else $bibl/descendant-or-self::biblStruct/monogr
    
    (: String join multiple title elements, which is useful for cases of parallel titles in multiple languages. :)
    let $title := 
      for $title in $titleLevel/title/text()
      (: string sorting, should solve multiple languages issue in case two different entries had the multiple languages in different orders :)
      order by $title
      return $title
    (: pipe join any sequence of titles :)
    let $title := string-join($title, " | ")
    return $title
};

let $syriacaZoteroNotOnApp :=
  for $bibl in $local:syriaca-zotero-dump
  let $zotUri := 
    for $uri in $bibl//biblStruct//idno
    where matches($uri/text(), $local:zotero-bibl-regex)
    return $uri/text()
  let $syriacaAppMatches :=
    for $syrBib in $local:syriaca-exist-dump
    let $syrBibUri := substring-before($syrBib//publicationStmt/idno/text(), "/tei")
    let $syrBibZotUri :=
      for $uri in $syrBib//biblStruct//idno[@type="URI"]
      where matches($uri/text(), $local:zotero-bibl-regex)
      return $uri/text()
    return if(substring-after($zotUri, "items/") = substring-after($syrBibZotUri, "items/")) then $syrBibUri else ()
  return if(count($syriacaAppMatches) = 0) then $bibl else ()
  
let $recs :=
  for $rec in $local:input-csv/*:csv/*:record
  let $syrUri := $rec/*:syriacaBiblUri/text()
  let $syrZotUri := $rec/*:syriacaZoteroUri/text()
  let $uriToMatch := if($syrUri != "") then $syrUri else $syrZotUri
  let $matchingBib :=
    for $bibl in ($local:syriaca-exist-dump, $syriacaZoteroNotOnApp)
    let $matchingSyriacaUri := $bibl//publicationStmt/idno/text()
    let $matchingSyriacaUri := substring-before($matchingSyriacaUri, "/tei")
    
    let $matchingSyriacaZoteroUri := 
      for $uri in $bibl//biblStruct//idno
      where matches($uri/text(), $local:zotero-bibl-regex)
      return $uri/text()
    let $matchingSyriacaZoteroUri := if($matchingSyriacaZoteroUri != "") then "https://zotero.org"||substring-after($matchingSyriacaZoteroUri, "otero.org") else ()
    
    where $uriToMatch = $matchingSyriacaZoteroUri or $uriToMatch = $matchingSyriacaUri
    return $bibl
  where not(empty($matchingBib))
  let $year := 
    if($rec/*:syriaca_year/text() != "") then 
      $rec/*:syriaca_year
    else 
      element {name($rec/*:syriaca_year)} {local:get-bibl-date($matchingBib)}
      
  let $authorsEditors := 
    if($rec/*:syriaca_authors-editors/text() != "") then 
      $rec/*:syriaca_authors-editors
    else 
      element {name($rec/*:syriaca_authors-editors)} {local:get-author-editor-string($matchingBib)}
   
  let $title := 
    if($rec/*:syriaca_title/text() != "") then
      $rec/*:syriaca_title
    else
      element {name($rec/*:syriaca_title)} {local:get-bibl-title($matchingBib)}
   
   let $formattedCitation := $matchingBib//bibl[@type="formatted" and @subtype="bibliography"]
   let $formattedCitation :=  normalize-space(string-join($formattedCitation//text()))
   
   return
     element {"record"} {
       $rec/*:syriacaBiblUri,
       $rec/*:syriacaZoteroUri,
       element {"syriacaCmosFormattedCitation"} {$formattedCitation},
       $rec/*:cbscZoteroUri,
       $year,
       $rec/*:cbsc_year,
       $authorsEditors,
       $rec/*:cbsc_authors-editors,
       $title,
       $rec/*:cbsc_title,
       $rec/*:match-type,
       $rec/*:correctedCBSCMatch,
       $rec/*:notes,
       $rec/*:checkedBy,
       $rec/*:status,
       $rec/*:hasPossibleMatch,
       $rec/*:potentialMatchNumber
     }
return csv:serialize(<csv>{$recs}</csv>, map {"header": "yes"})