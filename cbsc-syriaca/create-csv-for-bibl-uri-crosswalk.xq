xquery version "3.1";

(:
Rather than create a CSV this should just create an xml dump. We can use oXygen forms to allow students to review them
:)

declare default element namespace "http://www.tei-c.org/ns/1.0";

import module namespace functx="http://www.functx.com";

declare variable $local:reference-column-name-base := "syriaca_";
declare variable $local:comparison-column-name-base := "cbsc_";

declare variable $local:syriaca-zotero-group-id := "392292";

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

(:
match function
@param ref
@param compare

- if dates do not match, return 'miss'
- exact match title; fuzzy match if not
- exact match author/editor string; fuzzy match if not
- if both are exact, return 'exact'
- if author is fuzzy, return 'fuzzy author'
- if title if fuzzy, return 'fuzzy title and author'
- otherwise no match
:) 

declare function local:compare-bibl-pair($ref as node(), $compare as node())
as node()
{
  let $refYear := local:get-bibl-date($ref)
  let $compareYear := local:get-bibl-date($compare)
  
  let $refAuthEd := local:get-author-editor-string($ref)
  let $compareAuthEd := local:get-author-editor-string($compare)
  
  let $refTitle := local:get-bibl-title($ref)
  let $compareTitle := local:get-bibl-title($compare)
  
  (: start with simply yes or no matching; then try to implement fuzzy matches... :)
  let $matchResult := 
  if($refYear = $compareYear) (: if the years are different, it isn't a match :)
    then if($refAuthEd = $compareAuthEd and $refTitle = $compareTitle) then "1. exact match"
    else if ($refTitle = $compareTitle and local:is-fuzzy-match($refAuthEd, $compareAuthEd)) then "2. exact title and year, fuzzy creators"
    else if (local:is-fuzzy-match($refTitle, $compareTitle) and $refAuthEd = $compareAuthEd) then "3. exact creators and year, fuzzy title"
    else if(local:is-fuzzy-match($refTitle, $compareTitle) and local:is-fuzzy-match($refAuthEd, $compareAuthEd)) then "4. exact year, fuzzy creators and title"
    else "miss"
  else "miss"
  
  return
   element {"result"} {
     element {$local:reference-column-name-base||"year"} {$refYear},
     element {$local:comparison-column-name-base||"year"} {$compareYear},
     element {$local:reference-column-name-base||"authors-editors"} {$refAuthEd},
     element {$local:comparison-column-name-base||"authors-editors"} {$compareAuthEd},
     element {$local:reference-column-name-base||"title"} {$refTitle},
     element {$local:comparison-column-name-base||"title"} {$compareTitle},
     element {"match-type"} {$matchResult}
   }
};

declare function local:is-fuzzy-match($s1 as xs:string, $s2 as xs:string)
as xs:boolean
{
  $s2 contains text {$s1} using fuzzy   
};

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


declare function local:process-matches($matches as node()*)
as node()*
{
  if(empty($matches)) then () 
  else
    for $match in $matches
    order by $match/match-type/text()
    return $match
};

(: MAIN SCRIPT :)

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
  

for $bibl in ($local:syriaca-exist-dump, $syriacaZoteroNotOnApp)
let $syriacaUri := $bibl//publicationStmt/idno/text()
let $syriacaUri := substring-before($syriacaUri, "/tei")

(: the bibls in $syriacaZoteroNotOnApp have a spoofed syriaca URI with the key '-false' string :)
let $syriacaUri := if(contains($syriacaUri, "-false")) then () else $syriacaUri

let $syriacaZoteroUri := 
  for $uri in $bibl//biblStruct//idno
  where matches($uri/text(), $local:zotero-bibl-regex)
  return $uri/text()
let $syriacaZoteroUri := if($syriacaZoteroUri != "") then "https://zotero.org"||substring-after($syriacaZoteroUri, "otero.org") else ()

let $matches := 
  for $cBibl in $local:cbsc-zotero-dump[position() > 400 and position() < 500] (: delete [1], just for testing purposes to save on processing time :)
  let $cbscUri := $cBibl/@corresp/string()
  let $matchResult := 
    try {
      local:compare-bibl-pair($bibl, $cBibl)
   }
   catch * {
      let $error := 
    <error>
      <traceback>
        <code>{$err:code}</code>if($ed//surname) then $ed//surname
        <description>{$err:description}</description>
        <value>{$err:value}</value>
        <module>{$err:module}</module>
        <location>{$err:line-number||":"||$err:column-number}</location>
        <additional>{$err:additional}</additional>
      </traceback>
        <cbscUri>{$cbscUri}</cbscUri>
        {
          element {"syriacaBiblUri"} {$syriacaUri},
  element {"syriacaZoteroUri"} {$syriacaZoteroUri}
}
    </error>
    return $error
   }
  return 
    if($matchResult/match-type/text() != "miss") then 
      element {name($matchResult)} {
        attribute {"isMatch"} {},
        element {"cbscZoteroUri"} {$cbscUri},
        $matchResult/*     
      }
    else()
  
let $results := local:process-matches($matches)
let $hasMatch := if($results) then "true" else "false"

(: return the results as a csv row:)
return
element {"row"} {
  attribute {"checked"} {"false"},
  attribute {"status"} {"not checked"},
  attribute {"hasMatch"} {$hasMatch},
  element {"syriacaBiblUri"} {$syriacaUri},
  element {"syriacaZoteroUri"} {$syriacaZoteroUri},
  $results,
  element {"correctedCBSCMatch"} {},
  element {"correctedCBSCMatch"} {},
  element {"notes"} {},
  element {"checkedBy"} {}
}

(:
loop through the syriaca bibls
- [x] get the syriaca uri if it exists (and doesn't contain 'false')
- [x] get the corresponding zotero uri for the syriaca zot library

loop through the cbsc bibl list
- [x] pull out the zotero URI (@corresp attr)

feed the syriaca bibl and the cbsc bibl to the compare function
  - [x] write functions to extrac the data
  - implement fuzzy matching
  
process the results
  - pass the syriaca, syr zot, and cbsc zot urs to this function to add to each of the results (well, the zot uri needs to be in each result)
  
bundle up the results and return as a csv

csv fields:
  - [x] Syriaca bibl URI
  - [x] Syriaca Zotero URI
  - Syriaca author, title, and year (and maybe a full citation if it's available? want to construct it if it's not? useful comparison)
  - CBSC matched Zotero URI(s), "|" separated
  - CBSC author, title, and year ("|" separated as needed) (maybe a full citation)
  - match type:
    - 1. exact title, author, year
    - 2. fuzzy author, exact title, year
    - 3. fuzzy author and title, exact year
    - 4. miss
    - 5. multiple

:)