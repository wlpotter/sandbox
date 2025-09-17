xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $path-to-repo := "/home/arren/Documents/GitHub/britishLibrary-data/";
declare variable $input-collection := collection($path-to-repo||"data/tei/");

declare variable $bibl-lookup := csv:doc("/home/arren/Documents/GitHub/sandbox/smbl-bibl-cleanup/bibl-id-lookup.csv", map{"header": "yes"});

declare variable $cbss-uri-base := "http://syriaca.org/cbss/";
declare variable $zotero-uri-base := "https://www.zotero.org/groups/4861694/items/";

declare variable $zotero-regex-pattern := ".*zotero\.org/groups/4861694.+?items/[0-Z]{8}";

(: Turn the CSV -> XML doc -> an XQuery map for easy access :)
let $smblBiblLookup := map:merge(
  for $rec in $bibl-lookup/*:csv/*:record
  where $rec/*:cbss_uri/text() => normalize-space() != ""
  return map:entry($rec/*:temp_id/text(), $rec/*:cbss_uri/text())
)

for $doc in $input-collection
for $bibl in $doc//msDesc//bibl[not(ancestor::additional)]
where $bibl[ref]

let $oldTarget := $bibl/ref/@target/string()
let $newTarget := 
  (: If there's a Zotero record URL, extract the item key and prepend the CBSS URI:)
  if(contains($oldTarget, "zotero.org/groups/4861694")) then 
    concat($cbss-uri-base, functx:get-matches($oldTarget, $zotero-regex-pattern)[1] => substring-after("items/"))
  (: If it's a new citation with a temporary ID, and we've got the lookup for that ID, then replace it with the Zotero URI, and extract the item key and prepend CBSS URI :)
  else if(contains($oldTarget, "smblBibl") and functx:is-value-in-sequence($oldTarget, map:keys($smblBiblLookup))) then 
    let $zotUri := map:get($smblBiblLookup, $oldTarget)
    return concat($cbss-uri-base, functx:get-matches($zotUri, $zotero-regex-pattern)[1] => substring-after("items/"))
  (: Otherwise, it's either already a CBSS URI or it doesn't yet have a lookup in which case return the current value :)
  else $oldTarget
return replace value of node $bibl/ref/@target with $newTarget

