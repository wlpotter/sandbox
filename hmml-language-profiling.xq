xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare function local:get-length-from-locus($locus) {
  let $prefixes := ("fol", "page")
  let $normalized := replace($locus, "\[") => replace("\]")
  let $normalized := if(matches($normalized, "^\d")) then $normalized else (: handle the cases without a prefix :)
    for $pre in $prefixes
    where starts-with($normalized, $pre)
    let $regex := $pre ||"s?\.?\s*"
    return replace($normalized, $regex)
    
  let $ranges := tokenize($normalized, ",\s*")
  let $length := try {
    local:get-length-from-ranges($ranges, starts-with($locus, "page"))
  } catch * {
    "FAILURE"
  }
  return $length
};

declare function local:get-length-from-ranges($ranges, $isPages as xs:boolean)
{
  let $lengths :=
    for $range in $ranges
    let $nums := tokenize($range, "-")
    let $nums := if(count($nums) = 1) then ($nums, $nums) else $nums (: handle cases of a single num :)
    let $nums := for $n in $nums return replace($n, "\D+", "") => xs:integer()
    return $nums[2] - $nums[1] + 1
 let $total := sum($lengths)
 return if($isPages) then $total div 2 else $total
};

let $path := "/home/arren/Downloads/vHMML_fulldata_rr_20260204_3515.json"
let $doc := json:doc($path)
let $alphabet := "ABCDEFGHIJKLMNOPQRSTUVWXYZ" => tokenize("")

  let $recs := 
  for $ms in $doc/*:json/*:_
  let $uri := $ms/*:PURL/text()
  let $objectType := $ms/*:objectType/text()
  for $part at $i in $ms/*:parts/*:_
  let $langs := $part/*:contents/*:_/*:languages//*:name/text()
  let $partType := $part/*:type/string()
  let $distinctLangs := distinct-values($langs)
  
  (:
  - if there is only one language, print that language along with the ms URI
  - if there is only one contents, just print the semi-colon separated list of language with the ms URI
  :)
  return 
    if(count($distinctLangs) = 1 or count($part/*:contents/*:_) <= 1) then
      <rec>
        <uri>{$uri}</uri>
        <partLetter>{if(count($ms/*:parts/*:_) > 1) then $alphabet[$i] else ()}</partLetter>
        <langs>{string-join($distinctLangs, " ; ")}</langs>
        <langCount>{count($distinctLangs)}</langCount>
        <containsSyriac>{functx:is-value-in-sequence("Syriac", $distinctLangs)}</containsSyriac>
        <objectType>{$objectType}</objectType>
        <partType>{$partType}</partType>
        <locus>ALL</locus>
        <itemLength></itemLength>
      </rec>
    else 
      for $item in $part/*:contents/*:_
      let $itemNum := $item/*:id/text()
      let $locus := $item/*:itemLocation/text()
      let $itemLangs := $item/*:languages//*:name/text()
      
      let $itemLength := local:get-length-from-locus($locus)
      
      return 
      <rec>
        <uri>{$uri}</uri>
        <partLetter>{if(count($ms/*:parts/*:_) > 1) then $alphabet[$i] else ()}</partLetter>
        <langs>{string-join($itemLangs, " ; ")}</langs>
        <langCount>{count($itemLangs)}</langCount>
        <containsSyriac>{functx:is-value-in-sequence("Syriac", $itemLangs)}</containsSyriac>
        <objectType>{$objectType}</objectType>
        <partType>{$partType}</partType>
        <locus>{$locus}</locus>
        <itemLength>{$itemLength}</itemLength>
      </rec>
    
    

return <csv>{$recs}</csv> => csv:serialize(map {"header": "yes"})
(: return $recs :)