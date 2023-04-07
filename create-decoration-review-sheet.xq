xquery version "3.1";

import module namespace functx="http://www.functx.com";


declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:path-to-repo :=
  "/home/arren/Documents/GitHub/britishLibrary-data";

declare variable $local:in-coll :=
  collection($local:path-to-repo||"/data/tei/");
  
declare variable $local:archive-url-bases :=
("https://archive.org/details/catalogueofsyria01brituoft/page/",
 "https://archive.org/details/catalogueofsyria02brituoft/page/",
 "https://archive.org/details/catalogueofsyria03brituoft/page/");
 
 
let $recs :=
  for $doc in $local:in-coll
  (: where not($doc//msPart) :)
  let $fileUri := document-uri($doc)
  let $fileUri := substring-after($fileUri, $local:path-to-repo)
  where count($doc//decoNote > 0)
  
  for $decoNote in $doc//decoNote
  
  let $uri := $decoNote/../../../msIdentifier/idno[@type="URI"]/text()
  
  let $shelfmark := $decoNote/../../../msIdentifier/altIdentifier/idno[@type="BL-Shelfmark"]/text()
  
  let $decoId := $decoNote/@xml:id/string()
  let $decoType := $decoNote/@type/string()
  let $syriacaDecoType := tokenize($decoType, " ")[1]
  let $hmmlDecoType := tokenize($decoType, " ")[2]
  
  let $locus := 
    for $locus in $decoNote//locus
    let $range := if($locus/@to) then $locus/@from/string()||"-"||$locus/@to/string() else $locus/@from/string()
    return $range
  let $locus := string-join($locus, ", ")
  let $locus := if($locus != "") then "Fol. "||$locus else ()
  
  let $decoText := string-join($decoNote//text(), " ")
  let $decoText := normalize-space($decoText)
  
  let $volumeAndPage := $decoNote/../../../additional/listBibl/bibl/citedRange[@unit="pp"]/text()
  let $volume := substring-before($volumeAndPage, ":")
  let $volume := if($volume = "I") then "1" else if ($volume = "II") then "2" else if ($volume = "III") then "3" else $volume
  let $page := substring-after($volumeAndPage, ":")
  let $startPage := normalize-space(functx:substring-before-if-contains($page, "-"))
  
  let $archiveLink :=
    switch($volume)
    case "1" return $local:archive-url-bases[1]
    case "2" return $local:archive-url-bases[2]
    case "3" return $local:archive-url-bases[3]
    default return "" 
  let $archiveLink := $archiveLink||$startPage
  
  return
  <rec>
    <fileName>{$fileUri}</fileName>
    <msOrPartUri>{$uri}</msOrPartUri>
    <shelfMark>{$shelfmark}</shelfMark>
    <decorationId>{$decoId}</decorationId>
    <decorationType_Syriaca>{$syriacaDecoType}</decorationType_Syriaca>
    <decorationType_HMML>{$hmmlDecoType}</decorationType_HMML>
    <description>{$decoText}</description>
    <locus>{$locus}</locus>
    <archiveCatalgoueLink>{$archiveLink}</archiveCatalgoueLink>
  </rec>
  
(: return $recs :)
  
return csv:serialize(<csv>{$recs}</csv>, map {"header": "yes"})

(:
Each row should have:
x fileid
x ms or part uri
x decoNote ID
decoNote text
x decoNote types (syriaca term | hmml term)

---
then add spaces for label
lookups for the hmml term (cf. the other google sheet)


:)