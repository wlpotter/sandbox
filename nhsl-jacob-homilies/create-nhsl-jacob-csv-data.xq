xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare namespace srophe="https://srophe.app";
declare default element namespace "http://www.tei-c.org/ns/1.0";


declare function local:get-corpus-incipit($corpusUri as xs:string, $corpusData as node()*)
as xs:string*
{
  for $record in $corpusData
  where $record//publicationStmt/idno/text() = $corpusUri
  return $record//text/body/div[@type="text"]/*[1]/text()
};


let $worksColl := "C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\works\tei\"
let $corpusColl := "C:\Users\anoni\Documents\GitHub\srophe\syriac-corpus\data\tei\"

let $recs :=
  for $doc in collection($worksColl)
  where $doc//text/body/bibl/author[@ref="http://syriaca.org/person/42"]
  let $uri := $doc//text/body/bibl/idno[1]/text()
  let $englishTitle := $doc//text/body/bibl/title[@xml:lang="en" and @srophe:tags="#syriaca-headword"]/text()
  let $syriacTitle := $doc//text/body/bibl/title[@xml:lang="syr" and @srophe:tags="#syriaca-headword"]/text()
  
  let $corpusUri := $doc//text/body/bibl//bibl[ptr/@target="http://syriaca.org/bibl/2331"]/citedRange[@unit="entry"]/@target
  let $corpusUri := string($corpusUri)
  
  let $incipit := $doc//text/body/bibl/note[@type="incipit" and @xml:lang="syr"]/quote/text()
  let $explicit := $doc//text/body/bibl/note[@type="explicit" and @xml:lang="syr"]/quote/text()
  
  let $incipit := if(not($incipit) and $corpusUri != "") then local:get-corpus-incipit($corpusUri, collection($corpusColl)) else $incipit
  return 
    <rec>
    {
      <uri>{$uri}</uri>,
      <englishTitle>{$englishTitle}</englishTitle>,
      <syriacTitle>{$syriacTitle}</syriacTitle>,
      <incipit>{$incipit}</incipit>,
      <explicit>{$explicit}</explicit>,
      <syriacCorpusUri>{$corpusUri}</syriacCorpusUri>
      
    }
    </rec>
return csv:serialize(<csv>{$recs}</csv>, map{"header": "true"})