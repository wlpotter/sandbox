xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace output = 'http://www.w3.org/2010/xslt-xquery-serialization';
(: declare option output:method 'csv'; :)
declare variable $local:input-collection-paths :=
  (: edit, remove, or add paths as needed. These will be collated to create a single sequence of documents :)
  ("/home/arren/Documents/GitHub/britishLibrary-data/data/tei/");
  
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
};

declare function local:stringify-node($node as node())
as xs:string
{
  let $nodeName := name($node)
  let $attrString := if($node/@*) then 
    for $attr in $node/@*
    return name($attr)||"='"||string($attr)||"'"
    else ""
  let $attrString := " "||string-join($attrString, " ")
  let $descendantString := 
    for $child in $node/child::node() (: just text or :)
    return switch(functx:node-kind($child))
      case "text" return $child
      case "element" return local:stringify-node($child)
      case "comment" return $child
      default return ""
  let $descendantString := string-join($descendantString)
  return "&lt;"||$nodeName||$attrString||"&gt;"||$descendantString||"&lt;/"||$nodeName||"&gt;"
};

(: let $inColl := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\manuscripts\tei\") :)

let $nodeToStructureMap := 
  for $doc in $local:input-collections
  let $msUri := $doc//msDesc/msIdentifier/idno[@type="URI"]/text()
  
  for $node in $doc//msContents//msItem//place (: need to set this to be a varaible. Maybe use //msItem/*[name() = $nodeName]? Doesn't solve if want to switch to additions...:)
  let $xpath := functx:path-to-node-with-pos($node)
  let $structure := local:stringify-node(local:extract-node-structure($node))
  let $msItemId := string($node/ancestor::msItem[position() = 1]/@xml:id)
  return map {"ms-uri": $msUri, "xpath": $xpath, "msItem-id": $msItemId, "node": local:stringify-node($node), "node-structure": $structure}

let $totalInstances := count($nodeToStructureMap)
let $uniqueStructures := 
  for $instance in $nodeToStructureMap
    return $instance("node-structure")
let $uniqueStructures := distinct-values($uniqueStructures)

let $structureDataMap := 
  for $structure at $i in $uniqueStructures
  let $structId := "structure-"||$i
  let $hits := 
    for $node in $nodeToStructureMap
    where deep-equal($structure, $node("node-structure"))
    return <hit/>
  let $numberOfHits := count($hits)
  let $hitPercent := string(100 * (xs:float($numberOfHits) div xs:float($totalInstances)))
  return map {"structure-id": $structId, "structure": $structure, "hits": $numberOfHits, "hit-percentage": $hitPercent}

let $nodeToStructureMap :=
  for $instance in $nodeToStructureMap
  let $matchedStructureId :=
    for $struct in $structureDataMap
    where deep-equal($struct("structure"), $instance("node-structure"))
    return $struct("structure-id")
  return map:put($instance, "structure-id", $matchedStructureId)

let $keys-to-csv := function($k, $v)
{
  element {$k} {$v}
}
let $csvOfNodes := 
  <csv>
  {
    for $map in $nodeToStructureMap
    return <row>{map:for-each($map, $keys-to-csv)}</row>
  }
  </csv>
let $csvOfStructures := 
  <csv>
  {
    for $map in $structureDataMap
    return <row>{map:for-each($map, $keys-to-csv)}</row>
  }
  </csv>
(: return csv:serialize($csvOfNodes, map{"header": "yes"}) :)
return csv:serialize($csvOfStructures, map{"header": "yes"})