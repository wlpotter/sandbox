xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare variable $path-to-csv := "/home/arren/Documents/GitHub/sandbox/cbss-title-language/cbss-updated-language-info.csv";

declare variable $in-csv := csv:doc($path-to-csv, map{"header": true(), "format": "direct"});

(: UPDATE THIS TO MAP CSV COLUMN NAMES TO OUTPUT JSON KEYS :)
declare variable $header-map := map {
  "ItemKey": "itemKey",
  "TitleLang": "title_language",
  "PubLang": "publication_language",
  "LangNote": "language_note"
};

(: gather the CSV rows into an array of maps, to be serialized as JSON :)
let $data :=
array:build(
  for $row in $in-csv/csv/record
  (:
  For each row, create a map replacing the keys in the $header-map
  with the corresponding values in the CSV column headers
  :)
  return map:build(
    map:keys($header-map),
    value := fn{
      let $col_h := map:get($header-map, .)
      return $row/*[name() = $col_h]/text()
    }
  )
)
(: copy the result into a JSON file and save to be used as the input for the 
   Zotero ingest JavaScript
:)
return $data => json:serialize()
