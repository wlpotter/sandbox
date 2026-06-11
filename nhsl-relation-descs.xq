xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare namespace srophe="https://srophe.app";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace output = 'http://www.w3.org/2010/xslt-xquery-serialization';

declare option output:omit-xml-declaration 'no';
declare option output:indent 'yes';

declare variable $path-to-repo := "/home/arren/Documents/GitHub/syriaca-data/";
declare variable $works := collection($path-to-repo||"data/works/tei/");
declare variable $places := collection($path-to-repo||"data/places/tei/");
declare variable $persons := collection($path-to-repo||"data/persons/tei/");
declare variable $cbss := collection($path-to-repo||"data/bibl/tei/");


declare variable $cbssIndex :=
  map:merge(
    for $bibl in $cbss
    let $uri := $bibl/TEI/teiHeader/fileDesc/publicationStmt/idno[@type="URI"]/text() => substring-before("/tei")
    let $title := if($bibl/TEI/text/body/biblStruct/analytic) then $bibl/TEI/text/body/biblStruct/analytic/title[1] else $bibl/TEI/text/body/biblStruct/monogr/title[1]
    let $title := $title//text() => string-join(" ") => normalize-space()
    let $date := $bibl/TEI/text/body/biblStruct/monogr/imprint/date/text()
    return map {
      $uri: {
      "title": $title,
      "date": $date
      }
    }
);

(: Construct descs based on message and passive attributes :)
(: $andOr should be "and" or "or" and is used for joining multiple passives - defaults to 'and' sincle only isPartOf needs 'or' :)
declare function local:create-desc($message as xs:string, $passive as xs:string, $work as node(), $andOr as xs:string := "and")
as node() {
  element {"desc"} {
    attribute {"xml:lang"} {"en"},
    (: TBD delete this, just for debugging :)attribute {"source"} {$work/@xml:id/string()},
    $message,
    local:parse-passive($passive, $work, $andOr)
  }
};
(:
SHARED UTILS
:)
declare function local:parse-passive($passive as xs:string, $work as node(), $andOr as xs:string) {
  let $dereferencedPassives :=
    for $p in tokenize($passive)
    return 
      if(starts-with($p, "http://syriaca.org/work/")) then
        local:dereference-entity($p, $works, "TEI/text/body/bibl/title", "title")
      else if(starts-with($p, "http://syriaca.org/place/")) then
        local:dereference-entity($p, $places, "TEI/text/body/listPlace/place/placeName", "placeName")
        (: TBD: need either to parse to deprecated, or to wait until deprecated passives are cleaned up :)
      (: else if(starts-with($p, "http://syriaca.org/person/")) then
        local:dereference-entity($p, $persons, "TEI/text/body/listPerson/*/persName", "persName") :) (: can appear in person or personGrp elements :)
      else if(starts-with($p, "http://syriaca.org/cbss/")) then
        local:dereference-cbss($p)
      else local:dereference-bibl($p, $work) (: TBD: this function should work for both id frags (#bibxyz-n) and manuscript URIs :)
  return $dereferencedPassives => local:combine-dereferenced-passives($andOr)
};

declare function local:dereference-entity($uri as xs:string, $entities as node()+, $xpath as xs:string, $elName as xs:string) {
  let $matchedEntity := 
    for $e in $entities
    let $eUri := $e/TEI/teiHeader/fileDesc/publicationStmt/idno[@type="URI"]/text() => substring-before("/tei")
    where $uri = $eUri
    return $e
  let $headword := functx:dynamic-path($matchedEntity, $xpath)[starts-with(@xml:lang, "en")][contains(@srophe:tags, "#syriaca-headword")]//text()
    => string-join(" ") => normalize-space()
  
  return element {$elName} {
    attribute {"ref"} {$uri},
    $headword
  }
};

declare function local:dereference-cbss($uri as xs:string)
 {
  element {"title"} {
    attribute {"ref"} {$uri},
    $cbssIndex?$uri?title
  }
};

declare function local:dereference-bibl($id as xs:string, $work as node()) {
  let $matchedBibl := 
  if (starts-with($id, "#")) then
    $work/listBibl/bibl[@xml:id/string() = substring-after($id, "#")]
  else (: should just be the ms URIs, so strip the ending ref to the specific item... :)
    $work/listBibl/bibl[@type="syriaca:Manuscript"][ptr/@target/string() = $id][1] (: TBD: should remove the [1], just a temporary fix since duplicate mss with the same URI...:)
    
  return 
    if($matchedBibl/ptr/@target/string() => starts-with("http://syriaca.org/cbss/")) then 
      local:dereference-cbss($matchedBibl/ptr/@target/string())
    else if(not(starts-with($id, "#"))) then
      functx:add-attributes($matchedBibl/label[1], QName('', 'ref'), $id)
    else $matchedBibl/label[1]
};

(: TBD: fix to be node()+ and to use count < 1 for the first case :)
declare function local:combine-dereferenced-passives($passives as node()*, $andOr as xs:string)
as item()* {
  (: handle initial cases of 1 or 2 items :)
  if(count($passives) <= 1) then $passives
  else if(count($passives) = 2) then ($passives[1], " "||$andOr||" ", $passives[2])
  (: for 3 or more, need a serial semi-colon after all but the last :)
  else
    for $p at $i in $passives
    return 
      if($i < count($passives)) then ($p, "; ") (: until the last, just add a serial semi-colon :)
      else ($andOr||" ", $p) (: handle edge case for the last item :)
    
};

declare function local:format-bibl-type($type as xs:string)
as xs:string {
  switch ($type)
  case "lawd:Edition" return "edition"
  case "syriaca:ModernTranslation" return "modern translation"
  default return ""
};

(: MAIN :)
for $doc in $works
for $relation in $doc//listRelation/relation
let $biblType := local:format-bibl-type($relation/parent::listRelation/parent::bibl/@type)

let $desc := 
  switch($relation/@ref/string())
  case "syriaca:commemorates" return local:create-desc("This work commemorates ", $relation/@passive/string(), $doc/TEI/text/body/bibl)
  case "dcterms:source" return local:create-desc("This "||$biblType||" is based on ", $relation/@passive/string(), $doc/TEI/text/body/bibl)
  case "dcterms:isPartOf" return $relation/desc (: For now, leave these as-is :)
  case "skos:broader" return local:create-desc("This work is one version within ", $relation/@passive/string(), $doc/TEI/text/body/bibl)
  case "syriaca:different-from" return local:create-desc("Not the same conceptual work as ", $relation/@passive/string(), $doc/TEI/text/body/bibl, "or")
  default return $relation/desc (: If there happens to be another type, return the desc if it exists :)

return $desc