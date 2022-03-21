xquery version "3.1";


import module namespace functx="http://www.functx.com";


declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $in-coll := collection("C:\Users\anoni\Documents\GitHub\srophe\caesarea-data\data\testimonia\tei\");

declare function local:get-urn-and-ref-data($excerpt as node()?, $excerptType as xs:string)
as node()+
{
  let $urn := $excerpt/idno[@type="CTS-URN"]/text()
  let $urn := element {$excerptType||"Urn"} {$urn}
  let $urnBase := $excerpt/idno[@type="CTS-URN"]/@xml:base/string()
  let $urnBase := element {$excerptType||"UrnBase"} {$urnBase}
  
  let $refTarget := $excerpt/ref/@target/string()
  let $refTarget := element {$excerptType||"refTarget"} {$refTarget}
  
  return ($urnBase, $urn, $refTarget)
};

let $records :=
  for $doc in $in-coll
  let $uri := $doc//body/ab[@type="identifier"]/idno/text()
  let $uri := <uri>{$uri}</uri>
  
  let $title := $doc//titleStmt/title[@level="a"]//text()
  let $title := string-join($title, " ")
  let $title := <recordTitle>{$title}</recordTitle>
  
  let $editionUrnAndRefData := local:get-urn-and-ref-data($doc//body/ab[@type="edition"], "edition")
  
  let $translationUrnAndRefData := local:get-urn-and-ref-data($doc//body/ab[@type="translation"], "translation")
  
  return <record>{$uri, $title, $editionUrnAndRefData, $translationUrnAndRefData}</record>
return csv:serialize(<csv>{$records}</csv>, map{"header": "true"})