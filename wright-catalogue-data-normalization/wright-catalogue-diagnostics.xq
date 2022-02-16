xquery version "3.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare default element namespace "http://www.tei-c.org/ns/1.0";

let $inEditing := fn:collection("C:\Users\anoni\Documents\GitHub\srophe\wright-catalogue\data\5_finalized\")
let $msPartsHolding := fn:collection("C:\Users\anoni\Documents\GitHub\srophe\wright-catalogue\data\4_to_be_checked\")
let $inDev := fn:collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\manuscripts\tei\")

return fn:distinct-values(for $doc in $inDev
  let $uriList := $doc//msIdentifier/idno/text()
  for $uri in $uriList
    return fn:substring-after($uri, "manuscript/"))