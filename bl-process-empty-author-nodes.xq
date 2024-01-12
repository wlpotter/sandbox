xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace srophe="https://srophe.app";

declare variable $local:path-to-repo := "/home/arren/Documents/GitHub/britishLibrary-data/";
declare variable $local:input-collection := collection($local:path-to-repo||"data/tei/");

declare variable $local:syriaca-persons-collection :=
  collection("/home/arren/Documents/GitHub/srophe-app-data/data/persons/tei/");

for $item in $local:input-collection//msDesc//msItem
for $auth in $item/author
where not($auth//text())
let $authUri := $auth/@ref/string()
let $authHeadword := 
  for $pers in $local:syriaca-persons-collection
  let $persUri := $pers//publicationStmt/idno[@type="URI"]/text() => substring-before("/tei")
  where $authUri = $persUri
  let $headword := $pers//titleStmt/title[1]/text()[1] => substring-before("—") => normalize-space()
  (: let $headword := $pers//body/listPerson/person/persName[@xml:lang="en"][@srophe:tags="#syriaca-headword"]//text() => string-join(" ") => normalize-space() :)
  return $headword
return
  if(not($authUri)) then delete node $auth (: delete any author elements that lack a URI :)
  else replace value of node $auth with $authHeadword (: add the matching Syriaca headword to empty author elements :)
  (: note that this script will not fix cases of incorrect or multiple Syriaca author URIs. But it also shouldn't overwrite any since it first checks only those with no existing author text node :)