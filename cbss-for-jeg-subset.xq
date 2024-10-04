xquery version "3.1";



import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

(: I/O variables :)

declare variable $path-to-syriaca-records :=
  "/home/arren/Documents/GitHub/syriaca-data/data/";
  
declare variable $path-to-cbss-records :=
  "/home/arren/Documents/GitHub/syriaca-data/data/bibl/tei/";

declare variable $path-to-syriaca-production-bibls :=
  "/home/arren/Documents/Work_Syriaca/syriaca-bibls/bibl/tei/";
  
declare variable $output-dir := 
  "/home/arren/Documents/Work_Syriaca/cbss-joe-only/";

let $nothing := file:create-dir($output-dir)
  
let $persons-collection := collection($path-to-syriaca-records||"persons/tei/")
let $places-collection := collection($path-to-syriaca-records||"places/tei/")

(: get bibl URIs from JoE data :)
let $biblUris :=
  for $rec in ($persons-collection, $places-collection)
  where contains($rec//seriesStmt/idno/text() => string-join(" "), "http://syriaca.org/johnofephesus")
  return $rec//body//bibl/ptr/@target/string()

(: remove duplicates :)
let $biblUris := distinct-values($biblUris)

(: create a collection of bibl records from CBSS and a copy of the Syriaca production bibl records :)
let $cbssRecords := collection($path-to-cbss-records)
let $syriacaProductionRecords := collection($path-to-syriaca-production-bibls)

(: for each Syriaca bibl URI, find the matching CBSS or Syriaca bibl record and save to an output file :)
for $uri in $biblUris
where contains($uri, "syriaca.org/bibl") (: just get the syriaca bibls, not the pleiades :)
let $id := substring-after($uri, "/bibl/")
for $bibl in ($syriacaProductionRecords, $cbssRecords)
let $docId := document-uri($bibl) => functx:substring-after-last("/") => substring-before(".xml")
return if($docId = $id) then
  file:write($output-dir||$docId||".xml", $bibl)
  else
  ()
  
