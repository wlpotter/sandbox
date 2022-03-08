(:~ 
: @author William L. Potter
: @version 1.0
:)
import module namespace functx="http://www.functx.com";


declare default element namespace "http://www.tei-c.org/ns/1.0";


declare variable $local:current-branch := "new-places-from-Syriac-World";

(: declare variable $local:bibl-records := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\bibl\tei\"); :)
declare variable $local:deprecated-records := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\deprecated\");
declare variable $local:persons-records := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\persons\tei\");
declare variable $local:places-records := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\places\tei\");
declare variable $local:spear-records := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\spear\tei\");
declare variable $local:subjects-records := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\subjects\tei\");
declare variable $local:works-records := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\works\tei\");

declare variable $local:entities-to-select := ("person", "place", "work");

declare function local:create-referenced-uri-list($records as node()+, $entityTypesToSelect as xs:string+)
as xs:string+
{
  for $rec in $records
  let $referencedUris := 
    for $attr in $rec//*:body//@*
    where contains($attr, "://syriaca.org/")
    return $attr/string()
  
  (: divide entity references if they are in a space-separated list :)
  let $referencedUris :=
    for $uri in $referencedUris
    return tokenize($uri, "\s+")
    
  let $referencedUrisOfSelectedEntityType :=
    for $uri in $referencedUris
    (: let $entityType := substring-after($uri, "syriaca.org/")
    let $entityType := substring-before($entityType, "/") :)
    let $hasMatch := 
      for $entity in $entityTypesToSelect
      return if(contains($uri, $entity)) then "true"
    return if(not(empty($hasMatch))) then $uri
  return $referencedUrisOfSelectedEntityType
};
(: for now just looking at persons, places, and works. Maybe will need to look at spear and subjects? :)
let $records := ($local:persons-records, $local:places-records, $local:works-records, (: $local:bibl-records, :) $local:spear-records, $local:subjects-records, $local:works-records)

let $referencedEntityUris := local:create-referenced-uri-list($records, $local:entities-to-select)
let $referencedEntityUris := distinct-values($referencedEntityUris)

let $referencedEntityUris :=
  for $uri in $referencedEntityUris
  let $entityType := substring-after($uri, "syriaca.org/")
  let $entityType := substring-before($entityType, "/")
  return
  <record>
    <uri>{$uri}</uri>
    <entityType>{$entityType}</entityType>
    <branchName>{$local:current-branch}</branchName>
  </record>
  
return csv:serialize(<csv>{$referencedEntityUris}</csv>, map{"header": "true"})