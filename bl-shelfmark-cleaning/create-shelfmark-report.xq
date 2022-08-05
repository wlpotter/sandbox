declare default element namespace "http://www.tei-c.org/ns/1.0";

for $doc in collection("C:\Users\anoni\Documents\GitHub\srophe\britishLibrary-data\data\tei\")
let $docId := document-uri($doc)
let$docId := substring-after($docId, "britishLibrary-data")
let $title := $doc//titleStmt/title[1]
for $section in $doc//*[name() = "msDesc" or name() = "msPart"]
let $msId := $section/msIdentifier/idno/text()
let $shelfmark := $section/msIdentifier/altIdentifier/idno[@type="BL-Shelfmark"]/text()
return $docId||"	"||$msId||"	"||$title||"	"||$shelfmark