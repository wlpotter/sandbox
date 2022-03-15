import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

let $inColl := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\persons\tei") 
for $doc in $inColl
  let $fileNameId := document-uri($doc)
  let $fileNameId := functx:substring-after-last($fileNameId, "/tei/")
  let $fileNameId := substring-before($fileNameId, ".xml")
  
  let $uriLocalIdPublicationStmt := $doc//publicationStmt/idno[@type="URI"][1]/text()
  let $uriLocalIdPublicationStmt := substring-after($uriLocalIdPublicationStmt, "http://syriaca.org/person/")
  let $uriLocalIdPublicationStmt := substring-before($uriLocalIdPublicationStmt, "/tei")
  
  let $uriLocalIdBody := $doc//body/listPerson/person/idno[@type="URI"][1]/text()
  let $uriLocalIdBody := substring-after($uriLocalIdBody, "http://syriaca.org/person/")
  
  where $fileNameId != $uriLocalIdPublicationStmt or $fileNameId != $uriLocalIdBody
  return document-uri($doc)