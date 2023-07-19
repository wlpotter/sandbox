xquery version "3.0";


import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";


declare variable $local:in-coll := collection("/home/arren/Documents/GitHub/britishLibrary-data/data/tei/");

(:
takes either an msDesc with no parts or an msPart.
returns a node representing a CSV row with the following fields:
- ms-uri
- part-uri
- shelfmark
- origDate
- genre
- material
- folio extent
- form
- physDesc paragraph
- link to Archive catalogue
- wright volume
- wright pages

:)
declare function local:get-data-from-part-or-desc($part as node(), $msUri as xs:string) as node()
{
  let $partUri := $part/msIdentifier/idno[@type="URI"]/text()
  let $shelfmark := $part/msIdentifier/altIdentifier/idno[@type="BL-Shelfmark"]/text()
  let $origDate := local:get-origDate($part/history/origin/origDate)
  let $wrightGenre := $part/head/listRelation[@type="Wright-BL-Taxonomy"]/relation/desc/text()
  let $material := $part/physDesc/objectDesc/supportDesc/@material/string()
  let $extentFolios := $part/physDesc/objectDesc/supportDesc/extent/measure[@type="composition"][@unit="leaf"]/text()
  let $form := $part/physDesc/objectDesc/@form/string()
  let $physDesc := $part/physDesc/p//text()
  let $physDesc := string-join($physDesc, " ")
  let $physDesc := normalize-space($physDesc)
  let $archiveLink := $part/additional/listBibl/bibl/ref[@type="internet-archive-pdf"]/@target/string()
  let $wrightVolume := $part/additional/listBibl/bibl/citedRange[@unit="pp"]/text()
  let $wrightPages := substring-after($wrightVolume, ":")
  let $wrightPages := normalize-space($wrightPages)
  let $wrightVolume := substring-before($wrightVolume, ":")
  
  return 
  <row>
    <msUri>{$msUri}</msUri>
    <partUri>{$partUri}</partUri>
    <shelfmark>{$shelfmark}</shelfmark>
    {$origDate}
    <wrightGenre>{$wrightGenre}</wrightGenre>
    <material>{$material}</material>
    <extentFolios>{$extentFolios}</extentFolios>
    <form>{$form}</form>
    <physicalDescription>{$physDesc}</physicalDescription>
    <archiveLinke>{$archiveLink}</archiveLinke>
    <wrightVolume>{$wrightVolume}</wrightVolume>
    <wrightPages>{$wrightPages}</wrightPages>
  </row>
};

(: MAY NEED TO CHECK THE greater than one bits:)
(: HANDLE cases where no text node just attributes?:)
declare function local:get-origDate($origDate as node()*) as node()*
{
  let $origDate := 
    if(count($origDate) = 1) then (: if there's only one origDate, check that it is not a non-Gregorian date (those have a @datingMethod attribute) :)
      if($origDate/@datingMethod) then () else $origDate
    else if(count($origDate) = 0) then ()
    else $origDate[@calendar="Gregorian"]
  return
  (
    <origDateLabel>{normalize-space(string-join($origDate//text(), " "))}</origDateLabel>,
    <origDateNotBefore>{$origDate/@notBefore/string()}</origDateNotBefore>,
    <origDateNotAfter>{$origDate/@notAfter/string()}</origDateNotAfter>,
    <origDateWhen>{$origDate/@when/string()}</origDateWhen>
  )
};


let $rows :=
  for $doc in $local:in-coll
  
  let $msUri := $doc//msDesc/msIdentifier/idno[@type="URI"]/text()
   
   return
    if($doc//msPart) then 
      for $part in $doc//msPart
      return local:get-data-from-part-or-desc($part, $msUri)
   else
     local:get-data-from-part-or-desc($doc//msDesc, $msUri)
return csv:serialize(<csv>{$rows}</csv>, map {"header": "yes"})
(: return 
  try {
  if($doc//msPart) then 
    for $part in $doc//msPart
    return local:get-data-from-part-or-desc($part, $msUri)
 else
   local:get-data-from-part-or-desc($doc//msDesc, $msUri)   }
 catch* 
  {
    let $failure :=
      element {"failure"} {
        element {"code"} {$err:code},
        element {"description"} {$err:description},
        element {"value"} {$err:value},
        element {"module"} {$err:module},
        element {"location"} {$err:line-number||": "||$err:column-number},
        element {"additional"} {$err:additional},
        element {"msUri"} {$msUri}
      }
      return $failure
  } :)