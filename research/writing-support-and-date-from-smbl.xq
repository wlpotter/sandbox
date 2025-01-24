xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $path-to-repo := "/home/arren/Documents/GitHub/britishLibrary-data/";
declare variable $input-collection := collection($path-to-repo||"data/tei/");

declare function local:extract-origDate-and-support-from-part($part as node(), $msUri as xs:string)
as node() {
  let $uri := $part/msIdentifier/idno[@type="URI"]/text()
  let $support := $part/physDesc/objectDesc/supportDesc/@material/string()
  let $originExactDate := $part/history/origin/origDate[@calendar="Gregorian"]/@when/string()
  let $originStartDate := $part/history/origin/origDate[@calendar="Gregorian"]/@notBefore/string()
  let $originEndDate := $part/history/origin/origDate[@calendar="Gregorian"]/@notAfter/string()
  return 
    <rec>
      <msUri>{$msUri}</msUri>
      <partUri>{$uri}</partUri>
      <support>{$support}</support>
      <exactDate>{$originExactDate}</exactDate>
      <startDate>{$originStartDate}</startDate>
      <endDate>{$originEndDate}</endDate>
    </rec>
};

let $recs :=
  for $doc in $input-collection
  let $msDesc := $doc//msDesc
  let $msUri := $msDesc/msIdentifier/idno[@type="URI"]/text()
  let $data :=
    if($msDesc/msPart) then
      for $part in $msDesc//msPart
      return local:extract-origDate-and-support-from-part($part, $msUri)
      (: do stuff for parts :)
    else
      local:extract-origDate-and-support-from-part($msDesc, $msUri)
 return $data
 
return csv:serialize(<csv>{$recs}</csv>, map {"header": "yes"})