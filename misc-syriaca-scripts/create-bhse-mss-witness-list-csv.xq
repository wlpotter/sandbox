import module namespace functx="http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";

declare function local:process-bibl-data($bibl as node()?, $outputElementPrefix as xs:string)
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
};

declare function local:bibl-to-string($bibl as node()?)
{
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

for $doc in $inColl
(: in BHSE :)
where contains($doc//text/body/bibl/@ana/string(), "#hagiographic")

let $uri := $doc//text/body/bibl/idno[@type="URI"][1]/text()
let $bhsEntry := $doc//text/body/bibl/idno[@type="BHS"][1]/text()

for $ms in $doc//text/body/bibl/note[@type="MSS"]
let $msBiblId := $ms/bibl/@xml:id/string()
let $shelfmark := $ms/bibl/text()

let $correspEditionsData := 
  for $edition in $doc//text/body/bibl/note[@type="editions"]/bibl
  where contains($edition/@corresp, $msBiblId)
  return 
    <edition>
      <editionBiblId>{$edition/@xml:id/string()}</editionBiblId>
      <sourceBiblIdForEdition>{$edition/@source/string()}</sourceBiblIdForEdition>
    </edition>

let $correspEditions :=
  for $edition in $correspEditionsData/editionBiblId
  return <edition>{local:process-bibl-data($doc//text/body/bibl/note[@type="editions"]/bibl[@xml:id = $edition/text()], "correspEdition")}</edition>
  
return 
  <mss>
  {
    (element {"recordUri"} {$uri},
    element {"msBiblId"} {$msBiblId},
    element {"shelfmark"} {$shelfmark},
    $correspEditions
  )
    
  }
  </mss>