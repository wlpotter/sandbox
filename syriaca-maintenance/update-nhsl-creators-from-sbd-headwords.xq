xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace output = 'http://www.w3.org/2010/xslt-xquery-serialization';

declare option output:omit-xml-declaration 'no';
declare option output:indent 'yes';

declare variable $path-to-repo := "/home/arren/Documents/GitHub/syriaca-data/";
declare variable $works := collection($path-to-repo||"data/works/tei/");
declare variable $places := collection($path-to-repo||"data/places/tei/");
declare variable $persons := collection($path-to-repo||"data/persons/tei/");

(: Create a map of author URI to record title :)
let $personIndex := map:merge(
  for $person in $persons
  let $uri := $person/TEI/text/body/listPerson/*/idno[@type="URI"][1]/text()
  let $title := $person/TEI/teiHeader/fileDesc/titleStmt/title
  return map {$uri: $title}
)
for $doc in $works
where $doc//body/bibl/author or $doc//body/bibl/editor
for $creator in $doc//body/bibl/*[name() = "author" or name() = "editor"] (: include both authors and editors :)
let $creatorUri := $creator/@ref/string()
let $updatedCreator := 
  if($creatorUri != "") then 
    element {$creator/name()} {
      $creator/@ref,
      $creator/@source,
      $creator/@resp,
      $creator/@role,
      attribute {"xml:lang"} {"en"},
      $personIndex?$creatorUri/node() (: Look up the title in the author index and get the child text and element nodes :)
    }
  else $creator (: if there is no URI, then keep the author element as-is so we don't lose any data :)
return replace node $creator with $updatedCreator

