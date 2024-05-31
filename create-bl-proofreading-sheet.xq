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
 
declare variable $local:ms-uri-base := "http://bl.syriac.uk/ms/";

(: this is for multi-part manuscripts :)

let $recs :=
  for $doc in $local:in-coll
  where $doc//msPart
  let $fileUri := document-uri($doc)
  let $fileUri := substring-after($fileUri, $local:path-to-repo)
  
  for $part in $doc//msPart
  let $msUri := $part/msIdentifier/idno[@type="URI"]/text()
  
  let $shelfmark := $part/msIdentifier/altIdentifier/idno[@type="BL-Shelfmark"]/text()
  
  let $partNumber := $part/@xml:id/string()
  
  let $volumeAndPage := $part/additional/listBibl/bibl/citedRange[@unit="p"]/text()
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
      <msUri>{$msUri}</msUri>
      <shelfmark>{$shelfmark}</shelfmark>
      <partNumber>{$partNumber}</partNumber>
      <linkToPDF>{$archiveLink}</linkToPDF>
      <volume>{$volume}</volume>
      <startPage>{$startPage}</startPage>
    </rec>
return csv:serialize(<csv>{$recs}</csv>, map {"header": "true"})


(: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ :)
(: this is for single-part manuscripts :)
(: let $recs :=
  for $doc in $local:in-coll
  where not($doc//msPart)
  let $fileUri := document-uri($doc)
  let $fileUri := substring-after($fileUri, $local:path-to-repo)
  
  let $msUri := $doc//msDesc/msIdentifier/idno[@type="URI"]/text()
  
  let $shelfmark := $doc//msDesc/msIdentifier/altIdentifier/idno[@type="BL-Shelfmark"]/text()
  
  let $volumeAndPage := $doc//msDesc/additional/listBibl/bibl/citedRange[@unit="p"]/text()
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
      <msUri>{$msUri}</msUri>
      <shelfmark>{$shelfmark}</shelfmark>
      <partNumber/>
      <linkToPDF>{$archiveLink}</linkToPDF>
      <volume>{$volume}</volume>
      <startPage>{$startPage}</startPage>
    </rec>
return csv:serialize(<csv>{$recs}</csv>, map {"header": "true"}) :)