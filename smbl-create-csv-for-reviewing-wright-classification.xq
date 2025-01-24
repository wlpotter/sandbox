xquery version "3.0";


declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:path-to-repo :=
  "/home/arren/Documents/GitHub/britishLibrary-data";

declare variable $local:in-coll :=
  collection($local:path-to-repo||"/data/tei/");
  
let $recs :=
  for $doc in $local:in-coll

  let $fileName := document-uri($doc) => substring-after($local:path-to-repo||"/")
  let $fileUri := $doc//publicationStmt/idno[@type="URI"]/text() => substring-before("/tei")
  
  for $head in $doc//head
  let $msOrPartUri := $head/../msIdentifier/idno[@type="URI"]/text()
  
  let $classification := $head/listRelation[@type="Wright-BL-Taxonomy"]/relation/@passive/string()
  
  let $wrightBibl := $head/../additional/listBibl/bibl[ptr/@target = "http://syriaca.org/bibl/8"]
  
  let $vol := $wrightBibl/citedRange[@unit="vol"]/text()
  let $page := $wrightBibl/citedRange[@unit="p"]/text()
  let $archiveUrl := $wrightBibl/ref/@target/string()
  
  return <rec>
    <file>{$fileName}</file>
    <msUri>{$msOrPartUri}</msUri>
    <classification>{$classification}</classification>
    <wrightVol>{$vol}</wrightVol>
    <wrightPage>{$page}</wrightPage>
    <archiveLinke>{$archiveUrl}</archiveLinke>
  </rec>

return csv:serialize(<csv>{$recs}</csv>, map {"header": "yes"})
(:
- for each tei:head, get the classification
- use ../additional/listBibl/bibl... for Wright to get vol, page nums, and archive.org link
:)