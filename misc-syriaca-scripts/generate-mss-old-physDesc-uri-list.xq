xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare namespace srophe="https://srophe.app";
declare default element namespace "http://www.tei-c.org/ns/1.0";

let $inColl := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\manuscripts\tei")
for $doc in $inColl
where $doc//physDesc//measure/@unit != "content_pending"
let $docUri := $doc//msDesc/msIdentifier/idno[@type="URI"]/text()
let $fileUri := substring-after(document-uri($doc), "srophe-app-data")
return if(not($doc//msDesc/msPart)) 
  then ($fileUri||", "||$docUri)
  else 
    for $part in $doc//msDesc/msPart
    where $doc//physDesc//measure/@quantity != "-1"
    let $partUri := $part/msIdentifier/idno[@type="URI"]/text()
    let $partId := string($part/@xml:id)
    return ($fileUri||"#"||$partId||", "||$partUri)
  
