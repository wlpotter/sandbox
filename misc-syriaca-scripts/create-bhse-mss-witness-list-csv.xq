import module namespace functx="http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";

(: declare function local:process-bibl-data($bibl as node()?, $outputElementPrefix as xs:string)
{
  if(empty($bibl)) then ()
  else
  let $uri := element {$outputElementPrefix||".uri"} {$bibl/ptr/@target/string()}
  let $citedRange :=
    for $range in $bibl/citedRange
    let $unit := $range/@unit/string()
    let $text := $range/text()
    return $unit||" "||$text
  let $citedRange := element {$outputElementPrefix||".citedRange"} {string-join($citedRange, ", ")}
  
  let $citationString := local:bibl-to-string($bibl)
  let $citationString := element {$outputElementPrefix||".citationString"} {$citationString}
  return 
    <bibl>
      {$uri, $citedRange, $citationString}
    </bibl>
}; :)

declare function local:stringify-bibl($bibl as node()?)
as xs:string?
{
  (: author, editor, translator not built as they are not relevant to the BHS node, which is all I'm interested in at present :)
  let $mTitle := normalize-space($bibl/title[@level="m"]/text())
  let $citedRange := $bibl/citedRange/@unit/string()||" "||$bibl/citedRange/text()
  return $mTitle||", "||$citedRange
  (:
  - author
  - editor with (ed.) after each
  - translator (from editor/@role) with (tr.) after each
  - title
  - cited range in prose (e.g., "entry x, pp y-z")
  - note as `(note: "{note/text()}")`
  :)
};

let $inColl := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\works\tei\")

(: let $nonBhseNoteTypes :=
  for $doc in $inColl
  where contains($doc//text/body/bibl/@ana/string(), "#hagiographic")
  return $doc//text/body/bibl/note/@type/string()
return distinct-values($nonBhseNoteTypes) :)

let $msRecords := 
  for $doc in $inColl
  (: in BHSE :)
  where contains($doc//text/body/bibl/@ana/string(), "#hagiographic")
  
  let $uri := $doc//text/body/bibl/idno[@type="URI"][1]/text()
  let $bhsEntry := $doc//text/body/bibl/idno[@type="BHS"][1]/text()
  
  for $ms in $doc//text/body/bibl/note[@type="MSS"]
  let $msBiblId := $ms/bibl/@xml:id/string()
  let $shelfmark := $ms/bibl/text()
  
  let $correspEditions := 
    for $ed in $doc//text/body/bibl/note[@type="editions"]/bibl
    where contains($ed/@corresp, $msBiblId)
    return $ed/@xml:id/string()
  
  let $correspEditions := string-join($correspEditions, " ")
    
  let $sourceBiblId := $ms/@source/string()
  let $sourceBiblId := substring-after($sourceBiblId, "#")
  
  let $sourceBibl := $doc//text/body/bibl/bibl[@xml:id = $sourceBiblId]
  let $sourceBiblUri := $sourceBibl/ptr/@target/string()
  
  let $sourceBiblString := local:stringify-bibl($sourceBibl)
  
  return
    <mss>
    {
      (element {"recordUri"} {$uri},
      element {"msBiblId"} {$msBiblId},
      element {"shelfmark"} {$shelfmark},
      element {"sourceBiblId"} {$sourceBiblId},
      element {"sourceBiblUri"} {$sourceBiblUri},
      element {"sourceBiblString"} {$sourceBiblString},
      element {"correspEditionsBiblId"} {$correspEditions}
    )
      
    }
    </mss>
return csv:serialize(<csv>{$msRecords}</csv>, map {"header": "true"})