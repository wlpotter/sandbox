xquery version "3.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace srophe="https://srophe.app";

let $inColl := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\works\tei\")

let $csvOptions := map{'header': true ()}

let $records := 
  for $doc in $inColl
  where contains(string($doc/TEI/text/body/bibl/@ana), "#hagiographic")
  let $uri := substring-before($doc//publicationStmt/idno[@type="URI"]/text(), "/tei")
  let $enHeadword := string-join($doc//text/body/bibl/title[@srophe:tags="#syriaca-headword" and @xml:lang="en"]//text(), " ")
  let $syrHeadword := string-join($doc//text/body/bibl/title[@srophe:tags="#syriaca-headword" and @xml:lang="syr"]//text(), " ")
  let $authors := for $author in $doc//text/body/bibl/author return string-join($author//text(), " ")
  let $authors := string-join($authors, "#")
  let $authorsUri := for $author in $doc//text/body/bibl/author return string($author/@ref)
  let $authorsUri := string-join($authorsUri, "#")
  
  
  
  return
  <record>
    <uri>{$uri}</uri>
    <english-headword>{$enHeadword}</english-headword>
    <syriac-headword>{$syrHeadword}</syriac-headword>
    <authors>{$authors}</authors>
    <authorsUri>{$authorsUri}</authorsUri>
  </record>

let $xmlDoc := <csv>{$records}</csv>
return csv:serialize($xmlDoc, $csvOptions)