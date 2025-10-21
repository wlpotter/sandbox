xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $path-to-repo := "/home/arren/Documents/GitHub/britishLibrary-data/";
declare variable $input-collection := collection($path-to-repo||"data/tei/");

declare variable $smbl-taxonomy := doc("/home/arren/Documents/GitHub/sandbox/smbl-wright-taxonomy.xml");
(:
<listRelation type="Wright-BL-Taxonomy">
  <relation name="dcterms:type" ref="http://purl.org/dc/terms/type" active="https://bl.syriac.uk/ms/11" passive="#lectionaries">
    <desc>Lectionaries</desc>
  </relation>
</listRelation>
:)
(: takes a keyword term and returns the chain of broader taxonomy terms :)
declare function local:get-broader-categories($term, $taxonomy) {
  let $this := $taxonomy//category[@xml:id = $term]
  return $this/ancestor::category
};

declare function local:create-taxonomy-relation($categories, $msUri) {
  for $cat in $categories
  let $catId := $cat/@xml:id/string()
  let $catDesc := $cat/catDesc/text()
  return element {"relation"} {
    attribute{"name"} {"dcterms:type"},
    attribute{"ref"} {"http://purl.org/dc/terms/type"},
    attribute {"active"} {$msUri},
    attribute {"passive"} {"#"||$catId},
    element {"desc"} {$catDesc}
  }
};

(:
THE MAIN SCRIPT FOR UPDATING THE TAXONOMY IN THE HEAD
for $head in $input-collection//head
where $head[listRelation[@type="Wright-BL-Taxonomy"]]
let $uri := $head/../msIdentifier/idno[@type="URI"]/text()

let $listRelation := $head/listRelation[@type="Wright-BL-Taxonomy"]
let $broader :=
  for $rel in $listRelation/relation
  let $broaderCats := local:get-broader-categories(substring-after($rel/@passive/string(), "#"), $smbl-taxonomy)
  return local:create-taxonomy-relation($broaderCats, $uri)
  
return insert node $broader as last into $listRelation
:)
(: THE SECONDARY SCRIPT THAT UPDATES THE TAXONOMY ELEMENT IN EACH DOC :)
for $doc in $input-collection
return replace node $doc//TEI/teiHeader/encodingDesc/classDecl/taxonomy[@xml:id="Wright-BL-Taxonomy"] with $smbl-taxonomy