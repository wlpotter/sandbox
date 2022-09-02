xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:path-to-repo := "/home/arren/Documents/GitHub/britishLibrary-data/";

declare variable $local:collection :=
  collection($local:path-to-repo||"data/tei/");
  
let $titleData := 
  for $doc in $local:collection
  for $title in $doc//msDesc//msItem/title
  let $attrs := 
    for $a in $title/@*
    order by name($a)
    return name($a)
  let $attrs := string-join($attrs, "|")
  let $els :=
    for $el in $title/*
    order by name($el)
    return name($el)
  let $els := distinct-values($els)
  let $els := string-join($els, "|")
  return
  <title>
    <attributes>{$attrs}</attributes>
    <elements>{$els}</elements>
  </title>
  (:
  - get a list of attribute names, alpha order; | separate
  - get a list of element names, alpha order; | separate (do they need their attrs?)
  :)

let $titleData := functx:distinct-deep($titleData)
return csv:serialize(<csv>{$titleData}</csv>, map{"header": "yes", "separator": "comma"})