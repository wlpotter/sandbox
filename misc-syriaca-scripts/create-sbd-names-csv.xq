xquery version "3.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace srophe="https://srophe.app";

let $inColl := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\persons\tei\")

let $csvOptions := map{'header': true ()}

let $records := 
  for $doc in $inColl
  let $uri := $doc/TEI/text/body/listPerson/person/idno[@type="URI"][1]/text()
  let $uriLocalName := substring-after($uri, "syriaca.org/person/")
  let $isSaint := contains(string($doc/TEI/text/body/listPerson/person/@ana), "#syriaca-saint")
  let $isAuthor := contains(string($doc/TEI/text/body/listPerson/person/@ana), "#syriaca-author")
  
  (:
  - headwords are any tagged with #syriaca-headword
  - get the element
  - the node-name of the csv column is headword.langCode
  
  - anonymous desc is the same but with "#anonymous-description"
  
  - all other persNames should be /persName[not(@srophe:tags)]
  - these you keep an $i value that gives the namei
  :)
  let $headwords := 
    for $headword in $doc//text/body/listPerson/person/persName[@srophe:tags="#syriaca-headword"]
    let $langCode := string($headword/@xml:lang)
    let $nodeName := "headword."||$langCode
    return element {$nodeName} {normalize-space(string-join($headword//text(), " "))} (: the only issue is it adds a space before commas...:)
  
  let $anonymousDescs := 
    for $desc in $doc//text/body/listPerson/person/persName[@srophe:tags="#anonymous-description"]
    let $langCode := string($desc/@xml:lang)
    let $nodeName := "anonymous-desc."||$langCode
    return element {$nodeName} {normalize-space(string-join($desc//text(), " "))}
  
  let $names := 
    for $name at $i in $doc//text/body/listPerson/person/persName[not(@srophe:tags)]
    let $nodeName := "name"||$i
    return element {$nodeName} {normalize-space(string-join($name//text(), " "))}
  return
  <record>
    <id-no>{$uriLocalName}</id-no>
    <uri>{$uri}</uri>
    <isSaint>{$isSaint}</isSaint>
    <isAuthor>{$isAuthor}</isAuthor>
    {$headwords, $anonymousDescs, $names}
  </record>

let $headers := $records/*/name()
let $headers := distinct-values($headers)

let $records := 
  for $rec in $records
  let $headersToAdd := 
    for $header in $headers
    return if (not($rec/*[name() = $header])) then element {$header} {}
  return element {node-name($rec)} {$rec/*, $headersToAdd}
  

let $xmlDoc := <csv>{$records}</csv>
(: return $xmlDoc :)
return csv:serialize($xmlDoc, $csvOptions)