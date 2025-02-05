xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $path-to-repo := "/home/arren/Documents/GitHub/syriaca-data/";

declare variable $tsg := collection($path-to-repo||"data/places/tei/");
declare variable $sbd := collection($path-to-repo||"data/persons/tei/");
declare variable $nhsl := collection($path-to-repo||"data/works/tei/");

declare variable $path-to-deprecation-table := "/home/arren/Documents/GitHub/sandbox/cbsc-syriaca/out/deprecated-bibl-uri-crosswalk.csv";

declare variable $deprecation-table := csv:doc($path-to-deprecation-table, map{"header": "yes"});
declare variable $headers-map := map {
  "deprecated": "Deprecated_Syriaca_URI",
  "cbss": "CBSS_URI"
};


(: This function helps debugging bibls with no matching CBSS records, since it forces cardinality errors :)
declare function local:cardinality-error-checking($single-string as xs:string)
as xs:string {
  if(string-length($single-string) > 1) then
    $single-string
  else 1
};


(: $deprecation-table/csv/record/*[name() = $headers-map("deprecated")] :)

for $doc in $sbd
let $filePath := document-uri($doc) => substring-after($path-to-repo)
let $recUri := $doc//publicationStmt/idno[@type="URI"]/text() => substring-before("/tei")

for $bibl in $doc//bibl[ptr]
(: look only at bibls with an old Syriaca bibl URI :) (: Note: this will ignore Pleiades, wikidata, geonames, etc. citations, which is fine :)
where contains($bibl/ptr/@target, "http://syriaca.org/bibl/")
let $currentBiblUri := $bibl/ptr/@target/string()

let $crosswalk := $deprecation-table/*:csv/*:record[./*[name() = $headers-map("deprecated")]/text() = $currentBiblUri]

return try {
  let $updatedCbssUri := local:cardinality-error-checking($crosswalk/*[name() = $headers-map("cbss")]/text() => normalize-space())
  return ()(: $updatedCbssUri :)
}
catch * { 
    <err>
      <recUri>{$recUri}</recUri>
      <bibId>{$bibl/@xml:id/string()}</bibId>
      <deprecatedUri>{$currentBiblUri}</deprecatedUri>
      <matchingUris>{$crosswalk/*[name() = $headers-map("cbss")]/text()}</matchingUris>
    </err>
}
(:
ERRORS to sort out:
- some are returning multiple hits in the crosswalk, which is a problem. Need to figure out which and why (use a try/catch for debugging)
- handle errors/reporting when there is no matching cbss bibl
- are there any deprecated CBSS records that need multiple redirects?
:)
(: return $updatedCbssUri :)
(:
Pre-reqs:
Script:
 

match the bibl URI with the table of Syriaca bibl URIs, and replace it with the CBSS URI

if no match, report to the console with the URI/file name of the record, the xml:id of the bibl, and the bibl URI that was not found
- possibly ignore ones that are Pleiades, geonames, etc.? (i.e., look for syriaca.org/bibl)

Optional if we also want to include title and author info in the XML rather than the xslt doing it --> my opinion is this should be the xslt's job, not mine
- get the item key portion of the CBSS URI
- open the bibl as a document using the full filepath (global variable of file path + item key + '.xml')
- based on the item type, get creator and title info, or get a formatted bibl to insert?

:)