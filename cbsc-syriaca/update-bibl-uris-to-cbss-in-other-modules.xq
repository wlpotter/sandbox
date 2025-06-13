xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $path-to-repo := "/home/arren/Documents/GitHub/syriaca-data/";

declare variable $tsg := collection($path-to-repo||"data/places/tei/");
declare variable $sbd := collection($path-to-repo||"data/persons/tei/");
declare variable $nhsl := collection($path-to-repo||"data/works/tei/");

declare variable $path-to-deprecation-table := "/home/arren/Documents/GitHub/syriaca-data/redirects.csv";

declare variable $deprecation-table := csv:doc($path-to-deprecation-table, map{"header": "yes"});
declare variable $headers-map := map {
  "deprecated": "Deprecated_URI",
  "cbss": "Redirect_URI"
};


(: This function helps debugging bibls with no matching CBSS records, since it forces cardinality errors :)
declare function local:cardinality-error-checking($single-string as xs:string)
as xs:string {
  if(string-length($single-string) > 1) then
    $single-string
  else 1
};

declare %updating function local:update-deprecated-bibls($collection as item()+) {
  for $doc in $collection
  let $filePath := document-uri($doc) => substring-after($path-to-repo)
  let $recUri := $doc//publicationStmt/idno[@type="URI"]/text() => substring-before("/tei")
  
  for $bibl in $doc//bibl[ptr]
  (: look only at bibls with an old Syriaca bibl URI :) (: Note: this will ignore Pleiades, wikidata, geonames, etc. citations, which is fine :)
  where contains($bibl/ptr/@target, "http://syriaca.org/bibl/")
  let $currentBiblUri := $bibl/ptr/@target/string()
  
  let $crosswalk := $deprecation-table/*:csv/*:record[./*[name() = $headers-map("deprecated")]/text() = $currentBiblUri]

  
  return try {
    (: add distinct values here in case the same bibl uri is mapped to the same cbss uri multiple times? :)
    let $updatedCbssUri := local:cardinality-error-checking($crosswalk/*[name() = $headers-map("cbss")]/text() => normalize-space())
    return replace value of node $bibl/ptr/@target with $updatedCbssUri
  }
  catch * {
    let $error :=
    <err>
      <filePath>{$filePath}</filePath>
      <recUri>{$recUri}</recUri>
      <bibId>{$bibl/@xml:id/string()}</bibId>
      <deprecatedUri>{$currentBiblUri}</deprecatedUri>
      <matchingUris>{$crosswalk/*[name() = $headers-map("cbss")]/text()}</matchingUris>
    </err>
    return update:output($error)
   }
};

(
  local:update-deprecated-bibls($tsg),
  local:update-deprecated-bibls($sbd),
  local:update-deprecated-bibls($nhsl)
)