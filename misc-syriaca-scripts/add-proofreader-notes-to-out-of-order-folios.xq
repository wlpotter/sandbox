xquery version "3.1";

(:
: @author William L. Potter
: @version 1.0
: This script adds notes to TEI manuscript records if the additions/list/item 
: elements either lack a locus or their locus/@from attributes indicate they
: are not in the correct order.
: 
:)
import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:path-to-repo := "/home/arren/Documents/GitHub/britishLibrary-data/";

declare variable $local:collection :=
  collection($local:path-to-repo||"data/tei/");

declare variable $local:missing-locus-message := "N.B., one or more addition items lack locus information.";

declare variable $local:out-of-order-locus-message := "N.B., one or more addition items is not listed in folio order.";

declare function local:is-folio-seq-in-order($seq as xs:string*)
as xs:boolean
{
  let $vals :=
    for $item at $i in $seq
      return if ($i < count($seq)) then
      let $next := $seq[$i + 1]
      
      let $itemNum := functx:substring-before-match($item, "[ab]")
      let $itemNum := xs:integer($itemNum)
      let $itemSide := functx:substring-after-last-match($item, "\d+")
      let $nextNum := functx:substring-before-match($next, "[ab]")
      let $nextNum := xs:integer($nextNum)
      let $nextSide := functx:substring-after-last-match($next, "\d+")
      return if($nextNum > $itemNum) then 0 (: correct order, next item numerically greater :)
      else if($itemNum > $nextNum) then 1 (: incorrect order, next item numerically smaller :)
      else if($nextSide >= $itemSide) then 0 (: when numerically equal, next item is the verso ('b') or they are the same :)
      else 1 (: only option remaining is that the itemSide is the verso ('b') while the nextSide is the recto ('a'), meaning they are out of order :)
    else 0
  return sum($vals) = 0
};

for $doc in $local:collection

let $msUri := $doc//msDesc/msIdentifier/idno/text()

for $unit in $doc//*[name() = "msDesc" or name()="msPart"]
where $unit/physDesc//additions
let $unitUri := $unit/msIdentifier/idno/text()

let $additionsSequence := $unit/physDesc//additions/list/item

let $locusFromSequence := 
  for $add in $additionsSequence
  return if(count($add/locus/@from) = 1) then
    $add/locus/@from/string()
  else if(count($add/locus/@from) < 1) then
    "null"
  else  
    let $locusFromAttrs := 
      for $from in $add/locus/@from/string()
      return if($from != "") then $from else "null"
    let $locusFromAttrs := functx:sort($locusFromAttrs)
    return $locusFromAttrs[1]

let $locusFromSequence :=
  for $from in $locusFromSequence
  return if($from != "") then $from else "null"

let $missingLocusNote := if(functx:is-value-in-sequence("null", $locusFromSequence)) then
  element {QName("http://www.tei-c.org/ns/1.0", "note")} {attribute {"type"} {"proofreader-note"}, $local:missing-locus-message}
  else()
  
let $nonEmptyLocusSequence :=
  for $locus in $locusFromSequence
  where $locus != "null"
  return $locus

let $outOfOrderNote := 
try {
  if(not(local:is-folio-seq-in-order($nonEmptyLocusSequence)) and not(empty($nonEmptyLocusSequence))) then
  element {QName("http://www.tei-c.org/ns/1.0", "note")} {attribute {"type"} {"proofreader-note"}, $local:out-of-order-locus-message}
  else()
}
catch*{
   'Error [' || $err:code || ']: ' || $err:description  || '. line ' || $err:line-number || '|| Affected item: ' || $unitUri || " | "|| string-join($nonEmptyLocusSequence, ", ")
}

return insert node ($missingLocusNote, $outOfOrderNote) as first into $unit/physDesc//additions