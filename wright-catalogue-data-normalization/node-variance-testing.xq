xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:input-collection-paths :=
  (: edit, remove, or add paths as needed. These will be collated to create a single sequence of documents :)
  ("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\manuscripts\tei\");
  
declare variable $local:input-collections :=
  for $path in $local:input-collection-paths
  return collection($path);

(:~ 
: Given a node, $node, returns a skeleton outline of that node with attributes
: replaced by an empty attribute with the same name and character data replaced
: with the string "CDATA"
: 
: @param $node is the node whose structure you want to extract
:
: If given,
: <node>
:   <el attr="abc">lorem <subel>more lorem</subel></el>
:   <otherEl>even more lorem</otherEl>
: </node>
: 
: will return,
: <node>
:   <el attr="">CDATA<subel>CDATA</subel></el>
:   <otherEl>CDATA</otherEl>
: </node>
: 
: This function primarily enables comparison of variances in a given data model
:)
declare function local:extract-node-structure($node as node())
{
  element {node-name($node)}
  {
    for $child in $node/child::node() | $node/@*
    return
      switch(functx:node-kind($child))
      case "attribute" return attribute {node-name($child)} {"VALUE"}
      case "text" return "CDATA"
      case "element" return local:extract-node-structure($child)
      case "comment" return comment {"COMMENT"}
      default return "unknown"
  }
  (:
  for descendant of $node, if it's cdata, return "CDATA", if it's an attribute return attribute {name()} {""}, and if it's an element, run this script on that element
  :)
};

(: let $inColl := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\manuscripts\tei\") :)

let $allInstances := 
  for $doc in $local:input-collections
  return $doc//msContents/msItem//author
let $allStructures := 
  for $instance in $allInstances
  return local:extract-node-structure($instance)
return functx:distinct-deep($allStructures)

(:
next layer of development:

- enumerate these structures
- check against the full list to see how many times they occur (and maybe calculate the percentage?)
- generated a list of URIs and xml:id context (or an absolute xpath?) for a given structure that can be dumped out as a list
:)

(: for testing :)
(: let $in := 
<el>
<!-- hello -->
<ell attr="d">hey</ell>
</el>
return local:extract-node-structure($in) :)