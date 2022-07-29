declare default element namespace "http://www.tei-c.org/ns/1.0";

declare function local:get-first-locus-from-descendant($msItem as node())
as node()*
{
  (: return 1 of 2 error states depending on if the msItem is the only item in msContents or not :)
  if(not($msItem/msItem)) then
    if (count($msItem/ancestor::msContents//msItem) = 1) then <desc>This is the only msItem in the msContents, check by hand.</desc>
    else <desc>Locus cannot be determined from descendant msItem element(s), check by hand.</desc>
  (: return state when a locus is found :)
  else if($msItem/msItem[1]/locus) then
    (: catch errors where a descendant has multiple locus elements :)
    if(count($msItem/msItem[1]/locus) > 1) then <desc>Multiple locus elements found in descendant. Check by hand.</desc>
    else
      $msItem/msItem[1]/locus
  (: otherwise, recurse, using depth-first tree-traversal :)
  else local:get-first-locus-from-descendant($msItem/msItem[1])
};

let $coll := collection("C:\Users\anoni\Documents\GitHub\srophe\britishLibrary-data\data\tei")
for $doc in $coll
for $msContents in $doc//msContents
let $idno := $msContents/../msIdentifier/idno/text()
let $docId := document-uri($doc)
let $docId := substring-after($docId, "britishLibrary-data")
for $item in $msContents//msItem
where not($item/locus)
let $itemId := $item/@xml:id/string()

(: where ($item/msItem or count($msContents//msItem) < 2) :)

let $locusFromDescendant := local:get-first-locus-from-descendant($item)
(: the error state will be logged to console if get-first-locus-from-descendant did not return a locus element :)
let $logError := if(name($locusFromDescendant) != "locus") then <error><docId>{$docId}</docId><msUri>{$idno}</msUri><itemId>{$itemId}</itemId>{$locusFromDescendant}</error> else false()

(: only include the starting locus value, the @from attribute, from the child locus :)
let $locusFromDescendant := element {QName("http://www.tei-c.org/ns/1.0", "locus")} {attribute {"from"} {$locusFromDescendant/@from}}

return if(not($logError)) then
  insert node $locusFromDescendant as first into $item
else update:output($logError)