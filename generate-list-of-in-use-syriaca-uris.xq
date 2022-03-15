(:~ 
: @author William L. Potter
: @version 1.0
:)
import module namespace functx="http://www.functx.com";


declare default element namespace "http://www.tei-c.org/ns/1.0";

(:
- get a list of all deprecated URIs on master
- get a list of all active on dev
- get a list of all deprecated on dev
- look through the branches and prs to get a list of other ones to check

- get a list of URIs that are referenced in app-data (handle http/https issue...)
  - idnos
  - @target in ptr and in ref
  - relation @active and @passive (may need to string-join?)
:)
declare variable $local:current-branch := "master";

declare variable $local:bibl-records := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\bibl\tei\");
declare variable $local:deprecated-records := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\deprecated\");
declare variable $local:persons-records := (
  (: collection("C:\Users\anoni\Documents\GitHub\srophe\draft-data\data\persons\sample-files\"),
  collection("C:\Users\anoni\Documents\GitHub\srophe\draft-data\data\persons\tei\"),
  collection("C:\Users\anoni\Documents\GitHub\srophe\draft-data\data\saints\") :)
);
declare variable $local:places-records := (
   collection("C:\Users\anoni\Documents\GitHub\srophe\bethqatraye-data\data\places\tei")
 );
declare variable $local:spear-records := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\spear\tei\");
declare variable $local:subjects-records := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\subjects\tei\");
declare variable $local:works-records := (
  (: collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\works\tei\"),
  collection("C:\Users\anoni\Documents\GitHub\srophe\draft-data\data\works\eKtobe\tei\"),
  collection("C:\Users\anoni\Documents\GitHub\srophe\draft-data\data\works\tei\") :)
);

declare function local:create-uri-list($records as node()+, $recordStatus, $branchName)
as node()+
{
  for $rec in $records
  let $uri := $rec//publicationStmt/idno[@type="URI"][1]/text()
  let $uri := substring-before($uri, "/tei")
  let $entityType := substring-after($uri, "syriaca.org/")
  let $entityType := substring-before($entityType, "/")
  let $docId := document-uri($rec)
  let $docId := substring-after($docId, "bethqatraye-data") (: hacked for draft-data; update this whenever you run on a different repo :)
  return
  <record>
    <uri>{$uri}</uri>
    <entityType>{$entityType}</entityType>
    <recordStatus>{$recordStatus}</recordStatus>
    <branchName>{$branchName}</branchName>
    <fileLocation>{$docId}</fileLocation>
  </record>
};
(: for now just looking at persons, places, and works. Maybe will need to look at spear and subjects? :)
let $activeRecords := ($local:persons-records, $local:places-records, $local:works-records)

let $activeUriList := local:create-uri-list($activeRecords, "draft-data", $local:current-branch)
let $deprecatedUriList := local:create-uri-list($local:deprecated-records, "active", $local:current-branch)
return csv:serialize(<csv>{$activeUriList, $deprecatedUriList}</csv>, map{"header": "true"})

(: let $attributes :=
  for $doc in $inColl
  for $attr in $doc//*:body//@*
  where contains($attr, "://syriaca.org/")
  return $attr/name()
return distinct-values($attributes) :)