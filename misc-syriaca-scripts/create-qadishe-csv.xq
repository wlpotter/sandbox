xquery version "3.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace srophe="https://srophe.app";

let $inColl := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\persons\tei\")

let $csvOptions := map{'header': true ()}

let $records := 
  for $doc in $inColl
  where contains(string($doc/TEI/text/body/listPerson/person/@ana), "#syriaca-saint")
  let $uri := substring-before($doc//publicationStmt/idno[@type="URI"]/text(), "/tei")
  let $enHeadword := string-join($doc//text/body/listPerson/person/persName[@srophe:tags="#syriaca-headword" and @xml:lang="en"]//text(), " ")
  let $syrHeadword := string-join($doc//text/body/listPerson/person/persName[@srophe:tags="#syriaca-headword" and @xml:lang="syr"]//text(), " ")
  
  
  return
  <record>
    <uri>{$uri}</uri>
    <english-headword>{$enHeadword}</english-headword>
    <syriac-headword>{$syrHeadword}</syriac-headword>
  </record>

let $xmlDoc := <csv>{$records}</csv>
return csv:serialize($xmlDoc, $csvOptions)