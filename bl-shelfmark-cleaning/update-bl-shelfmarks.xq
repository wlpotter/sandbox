xquery version "3.1";

import module namespace functx="http://www.functx.com";


declare default element namespace "http://www.tei-c.org/ns/1.0";

let $csv := csv:doc("shelfmarks_CLEAN.csv", map {"header": true(), "separator": "tab"})
let $inColl := collection("C:\Users\anoni\Documents\GitHub\srophe\britishLibrary-data\data\tei\")

for $doc in $inColl
let $msLevelUri := $doc//msDesc/msIdentifier/idno/text()
let $docUriRelative := substring-after(document-uri($doc), "britishLibrary-data")
let $docRows := 
  for $r in $csv/*:csv/*:record
  where string($r/*:fileLocation/text()) = string($docUriRelative)
  return $r
return replace value of node $doc//fileDesc/titleStmt/title[1] with $docRows[1]/*:recordTitle/text()
(: to update shelfmarks in the altIdentifier/idno elements, uncomment the below lines and comment out the line above :)
(: for $section in $doc//*[name() = "msDesc" or name() = "msPart"]
let $sectRow := for $r in $docRows
  where string($r/*:msUri/text()) = string($section/msIdentifier/idno/text())
  return $r
let $simplifiedShelfmarkIdno := element idno {attribute {"type"} {"BL-Shelmark-simplified"}, $sectRow/*:shelfmarkSimplified/text()}
return (
  replace value of node $section/msIdentifier/altIdentifier/idno[@type="BL-Shelfmark"]/text() with $sectRow/*:shelfmark/text(),
  insert node element altIdentifier {$simplifiedShelfmarkIdno} after $section/msIdentifier/altIdentifier[idno[@type="BL-Shelfmark"]]
) :)
