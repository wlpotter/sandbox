xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";


declare variable $path-to-repo := "/home/arren/Documents/GitHub/syriaca-data";

declare variable $persons-coll := collection($path-to-repo||"/data/persons/tei/");
declare variable $works-coll := collection($path-to-repo||"/data/works/tei/");

for $person in $persons-coll
let $personUri := $person//publicationStmt/idno[@type="URI"]/text() => substring-before("/tei")
(: return $personUri :)
for $workUri in $person//event[@type="attestation"]//title/@ref/string()
let $workRec :=
  for $work in $works-coll
  where $workUri||"/tei" = $work//publicationStmt/idno[@type="URI"]/text()
  return $work

let $commemorations := $workRec//relation[@name="syriaca:commemorated" or @ref="syriaca:commemorated"]/@passive => string-join(" ")
return if(contains($commemorations, $personUri)) then
  ()
  else $personUri||","||$workUri
  
(: the below doesn't handle cases where the commemorated relation has multiple, space-separated person URIs in the passive attribute :)
(: let $commemorations := $workRec//relation[@name="syriaca:commemorated"]/@passive
return if(functx:is-value-in-sequence($personUri, $commemorations)) then
  ()
  else $personUri||" | "||$workUri :)