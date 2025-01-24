xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace srophe="https://srophe.app";


declare default element namespace "http://www.tei-c.org/ns/1.0";


declare variable $path-to-repo := "/home/arren/Documents/GitHub/syriaca-data";

declare variable $persons-coll := collection($path-to-repo||"/data/persons/tei/");

let $recs :=
for $doc in $persons-coll
let $docId := document-uri($doc) => substring-after($path-to-repo)
let $uri := $doc//publicationStmt/idno[@type="URI"]/text() => substring-before("/tei")
let $persName := $doc//body//persName[@xml:lang="en"][@srophe:tags = "#syriaca-headword"]//text() 
  => string-join(" ")
  => normalize-space()
for $event in $doc//event[@type="veneration"]
let $xpath := functx:path-to-node-with-pos($event)
let $desc := $event/desc//text() => string-join(" ") => normalize-space()
let $religiousCommunityUri := $event/desc/rs/@ref/string()
let $religiousCommunityTextNode := $event/desc/rs/text()

(: dates :)
(:
type
when
source
when-custom
datingMethod
:)
let $when := $event/@when/string()
let $whenCustom := $event/@when-custom/string()
let $datingMethod := $event/@datingMethod/string()
let $source := $event/@source/string()

let $biblInfo := 
  for $s in tokenize($source, " ")
  let $biblId := substring-after($s, "#")
  for $bibl in $doc//bibl
  where $bibl/@xml:id/string() = $biblId
  let $biblUri := $bibl/ptr/@target/string()
  let $biblCitedRange := for $range in $bibl/citedRange return $range/@unit/string()||": "||$range/text()
  let $biblCitedRange := string-join($biblCitedRange, ". ")
  return $biblUri||"; "||$biblCitedRange
let $biblInfo := string-join($biblInfo, " | ")

let $data := 
<rec>
  <docId>{$docId}</docId>
  <recUri>{$uri}</recUri>
  <xpath>{$xpath}</xpath>
  <persName>{$persName}</persName>
  <desc>{$desc}</desc>
  <religiousCommunity>{$religiousCommunityTextNode}</religiousCommunity>
  <uri.ReligiousCommunity>{$religiousCommunityUri}</uri.ReligiousCommunity>
  <when>{$when}</when>
  <when-custom>{$whenCustom}</when-custom>
  <datingMethod>{$datingMethod}</datingMethod>
  <biblInfo>{$biblInfo}</biblInfo>
</rec>

  return $data
return csv:serialize(<csv>{$recs}</csv>, map{"header": "true"})