xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";


declare variable $local:bibls-to-process :=
    let $path-to-doc := "/home/arren/Documents/GitHub/sandbox/cbsc-syriaca/cbss_diff-recs_2021-12-20_comp-to-2023-08-01_Zotero-dump.xml"
    let $doc := doc($path-to-doc)
    return $doc/listBibl/biblStruct;

declare variable $local:cbss-search-url-base := "https://www.zotero.org/groups/4861694/a_comprehensive_bibliography_of_syriac/search/";

declare variable $local:cbss-search-url-postfix := "/titleCreatorYear";

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

let $recs :=
    for $bibl in $local:bibls-to-process
    let $creators := local:get-author-editor-string($bibl)
    let $date := local:get-bibl-date($bibl)
    let $title := local:get-bibl-title($bibl)
    let $uri := $bibl/@corresp/string()

    let $creatorsDateSearchString := $creators||" "||$date
    let $creatorsDateSearchString := 
        replace($creatorsDateSearchString, "\(ed\.\)", "")
        => replace(",", "")
        => normalize-space()
        => encode-for-uri()
    let $titleSearchString :=
        normalize-space($title)
        => encode-for-uri()

    return 
        element {"record"} {
            element {"creators"} {$creators},
            element {"date"} {$date},
            element {"title"} {$title},
            element {"sandbox_URI"} {$uri},
            element {"searchURL_CreatorDate"} {$local:cbss-search-url-base||$creatorsDateSearchString||$local:cbss-search-url-postfix},
            element {"searchURL_Title"} {$local:cbss-search-url-base||$titleSearchString||$local:cbss-search-url-postfix},
            element {"CBSS_URI"} {},
            element {"notes"} {},
            element {"status"} {"to do"},
            element {"assignee"} {}
    }
return csv:serialize(<records>{$recs}</records>, map {"header": "true"})