xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:path-to-repo := "/home/arren/Documents/GitHub/britishLibrary-data/";
declare variable $local:input-collection := collection($local:path-to-repo||"data/tei/");


(:## Counting parts ##:)
(: let $recs :=
  for $doc in $local:input-collection
  return if ($doc//msPart) then count($doc//msPart)
    else 1
return sum($recs) :)

(:## Counting hands that aren't additions ##:)

(: let $recs :=
  for $doc in $local:input-collection
    let $hands := 
      for $h in $doc//handNote
      let $text := string-join($h//text(), " ") => normalize-space() => lower-case()
      where not(contains($text, "see additions"))
      return $h
    return count($hands)
return sum($recs) :)

(:## Counting additions, esp. colophons ##:)

(: let $recs :=
  for $doc in $local:input-collection
  return count ($doc//additions/list/item[label[./text() = "Colophon"]])
return sum($recs) :)

(:## Max, min, and total of folio extents ##:)

(: let $recs :=
  for $doc in $local:input-collection
  for $extent in $doc//supportDesc/extent/measure[@unit="leaf"]/@quantity/string()
  return xs:integer($extent)
return (max($recs), min($recs), sum($recs)) :)

let $recs :=
  for $doc in $local:input-collection
  return $doc//supportDesc/@material
let $parchment := $recs[./string() = "perg"]
let $paper := $recs[./string() = "chart" or ./string() = "paper"]
let $mixed := $recs[./string() = "mixed"]
let $unknown := $recs[./string() = "unknown"]

return ("Parchment: "||count($parchment),
  "Paper: "||count($paper),
  "Mixed: "||count($mixed),
  "Unknown: "||count($unknown)
)
