xquery version "3.1";

import module namespace functx="http://www.functx.com";


declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $syriaca-data :=
  "/home/arren/Documents/GitHub/syriaca-data";
  
declare variable $tei-bibl-coll :=
  collection($syriaca-data||"/data/bibl/tei/");

declare variable $test-record :=
  doc($syriaca-data||"/data/bibl/tei/N7QTGJKT.xml");
  
declare variable $path-to-zotero-dump :=
  "/home/arren/cbss_data-dump_local_2024-07-02.json";
  
declare variable $zotero-dump :=
  file:read-text($path-to-zotero-dump) => json:parse();
  
declare variable $ignore-added-after-date := xs:date("2024-03-01");

(: for $item in $zotero-dump/json/items
return $item :)
let $zoteroKeys :=
  for $rec in $zotero-dump/json/items/_
  let $itemKey := $rec/itemKey/text()
  let $dateAdded := $rec/dateAdded/text() => substring-before("T")
  where xs:date($dateAdded) < $ignore-added-after-date
  return $itemKey

let $teiKeys :=
for $doc in $tei-bibl-coll
let $key := document-uri($doc) => substring-after("/data/bibl/tei/") => substring-before(".xml")
where $doc/tei:TEI/tei:text/tei:body/tei:biblStruct/@type/string() != "note"
return $key

(: return the keys that don't appear in the TEI records :)
for $key in $zoteroKeys
return if(functx:is-value-in-sequence($key, $teiKeys)) then ()
else $key