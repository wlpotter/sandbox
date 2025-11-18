(:
- set writeback true
- set exporter indent=yes,omit-xml-declaration=no
BASEX OPTIONS (pre v.10, whitespace handling has since changed):
- set chop off

:)
import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare option output:omit-xml-declaration "no";


declare variable $path-to-repo := "/home/arren/Documents/GitHub/syriaca-data/";

declare variable $path-to-csv := "/home/arren/Downloads/syriaca-idno-reingest-places.csv";
declare variable $csv-doc := csv:doc($path-to-csv, map {"header": "true"});

declare %updating function local:replace-idno($targetIdno, $row) {
  replace value of node $targetIdno with $row/*:idno_value_corrected/text() => normalize-space()
};

declare %updating function local:deprecate-idno($targetIdno, $row) {
  let $subtype := $targetIdno/@subtype/string()
  let $subtype := string-join(($subtype, "deprecated"), " ")
  let $replacement := functx:add-or-update-attributes($targetIdno, QName("", "subtype"), $subtype)
  return replace node $targetIdno with $replacement
};

for $row in $csv-doc/*:csv/*:record
where $row/*:action/text() => normalize-space() != "skip"

let $doc := doc($path-to-repo||$row/*:filepath)

let $xpath := $row/*:xpath_with_pos/text() => normalize-space()
let $position := substring-after($xpath, "[") => functx:substring-before-if-contains("]")
let $position := max(($position, '1'))
let $xpath := functx:substring-before-if-contains($xpath, "[")
(: return $xpath||"["||$position||"]" :)
let $idnos := functx:dynamic-path($doc, $xpath)
let $targetIdno := $idnos[position() = xs:integer($position)]

return if($row/*:idno_value_original/text() => normalize-space() = $targetIdno/text() => normalize-space()) then
  switch ($row/*:action/text() => normalize-space())
  case "replace" return local:replace-idno($targetIdno, $row)
  case "delete" return delete node $targetIdno
  case "deprecate" return local:deprecate-idno($targetIdno, $row)
  case "skip" return ()
  default return ()
else
  update:output("Values of idno elements don't match. Expected: "||$row/*:idno_value_original/text() => normalize-space()||". Actual: "||$targetIdno/text() => normalize-space())