xquery version "3.1";

import module namespace zotero2tei="http://syriaca.org/zotero2tei" at "/home/arren/Documents/GitHub/zotero2bibl/zotero2tei.xqm";

declare default element namespace "http://www.tei-c.org/ns/1.0";


declare variable $path-to-json-files := "/home/arren/Documents/GitHub/zotcsv/cbss_modified-since_2024-01-19.json";

declare variable $output-directory := "/home/arren/Documents/GitHub/syriaca-data/data/bibl/tei/";

declare variable $json-data := json:doc($path-to-json-files, map {"format": "xquery"});

(:
NOTE: for some reason, we got duplicate versions of the same records returned...so a first step parses out the distinct item keys
:)
let $distinctKeys :=
  for $rec in $json-data?*
  return $rec?key
let $distinctKeys := distinct-values($distinctKeys)

for $key in $distinctKeys
  (: find the array positions that have a map with a 'key' key that has the same value :)
  let $matchingPositions :=
    array:index-where($json-data, 
      fn($member) {
        $member?key = $key
      })
  let $json := $json-data?$matchingPositions[1] (: get the map at the first matching position in the array :)
  let $tei := zotero2tei:build-new-record($json, $json?key, "json")
  let $filePath := $output-directory||$json?key||".xml"
  return put($tei, $filePath)