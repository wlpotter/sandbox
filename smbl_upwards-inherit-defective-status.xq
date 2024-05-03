xquery version "3.1";
import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $defective-attr := attribute {"defective"} {"true"};

declare variable $path-to-repo := "/home/arren/Documents/GitHub/britishLibrary-data/";

declare variable $in-coll := collection($path-to-repo||"data/tei/");

(: 
Sample series of msItems used in testing and development
declare variable $msItemTest :=
<container>
<msItem xml:id="a1" n="1">
  <locus to="15" from="1a">Foll. 1a-15</locus>
  <msItem xml:id="b1" n="2">
    <locus to="7" from="1a">Foll. 1a-7</locus>
     <msItem xml:id="c1" n="2" defective="true">
    <locus to="7" from="1a">Foll. 1a-7</locus>
  </msItem>
  </msItem>
  <msItem xml:id="b2" n="3">
    <locus to="15" from="8a">Foll. 8a-15</locus>
  </msItem>
</msItem>
<msItem xml:id="a2" n="4">
  <locus to="23" from="15b">Foll. 15b-23</locus>
</msItem>
</container>;
:)

declare function local:upwards-inherit-defective-status($msItem as node())
as item()*
{
  (: base case :)
  let $isCurrentNodeDefective := boolean($msItem[@defective="true"])
  return
    if (not($msItem/msItem)) then
      map {
        "item": $msItem,
        "defective": $isCurrentNodeDefective
      }
    else
      let $childData :=
        for $item in $msItem/msItem
        return local:upwards-inherit-defective-status($item)
      let $defectiveValuesForChildren := map:find($childData, "defective")
      let $defectiveChildrenArray := array:filter($defectiveValuesForChildren, function($i) {$i})
      let $hasDefectiveChild := (array:size($defectiveChildrenArray) > 0)
      (:
      if current is defective or has def children, add the defective attribute
      return the item with the children replaced from childData --> $msItem/@*, defective attribute, /* not msItem, 
      :)
      let $updatedItem :=
        element {"msItem"} {
          $msItem/@*[not(name() = "defective")],
          if(boolean($isCurrentNodeDefective or $hasDefectiveChild)) then $defective-attr else (),
          $msItem/*[not(name() = "msItem")],
          map:find($childData, "item")
        }
      return 
        map {
          "defective": boolean($isCurrentNodeDefective or $hasDefectiveChild),
          "item": $updatedItem
        }
};

for $doc in $in-coll
let $docId := document-uri($doc) => substring-after($path-to-repo)
for $msContents in $doc//msContents
let $updatedItems :=
  for $item in $msContents/msItem
    return local:upwards-inherit-defective-status($item)("item")
let $updatedContents := 
  element {"msContents"} {
    $msContents/*[not(name() = "msItem")],
    $updatedItems
  }
(: return functx:add-attributes($updatedContents, QName("", "docId"), $docId) :)
return replace node $msContents with $updatedContents