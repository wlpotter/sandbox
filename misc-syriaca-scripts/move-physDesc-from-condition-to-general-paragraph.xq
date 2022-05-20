xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare option output:indent "no";
declare option output:omit-xml-declaration "no";

declare variable $local:in-coll := collection("C:\Users\anoni\Documents\GitHub\srophe\britishLibrary-data\data\tei");

(: for $doc in $local:in-coll
let $partUris := 
  for $part in $doc//msPart
  where not($part/physDesc/p)
  return $part/msIdentifier/idno[@type="URI"]/text()
let $uri := if($doc//msDesc/physDesc[not(p)]) then $doc//msDesc/msIdentifier/idno[@type="URI"]/text()
return ($uri, $partUris) :)

for $doc in $local:in-coll
for $physDesc in $doc//msDesc//physDesc[not(p)]
let $physical-description-text := $physDesc/objectDesc/supportDesc/condition/list/item/p
return insert node $physical-description-text as first into $physDesc
(:
- if a physDesc doesn't have a child p then the physical-description-text should come from the physDesc/objectDesc/supportDesc/condition/list/item/p
- this text should be inserted as first into the physDesc
:)