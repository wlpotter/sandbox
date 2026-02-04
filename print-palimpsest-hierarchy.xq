import module namespace functx = "http://www.functx.com";
declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $input-directory := "/home/arren/Documents/GitHub/britishLibrary-data/data/tei/";

declare function local:collate-part-info($part as node(), $tabs as xs:integer) {
  let $uri := $part/msIdentifier/idno[@type="URI"]/text()
  let $shelfmark := $part/msIdentifier/altIdentifier/idno[@type="BL-Shelfmark"]/text()
  
  let $indent := for $i in 1 to $tabs return "	"
  let $indent := string-join($indent, "")
  let $returnString := $indent||$shelfmark||" | ("||$uri||")
"

  return concat(
      $returnString,
      for $subpart in $part/msPart
      return local:collate-part-info($subpart, $tabs+1)
    )
};

for $doc in collection($input-directory)
where $doc//relation[@name="syriaca:has-palimpsest-upper"] or $doc//relation[@name="syriaca:has-palimpsest-lower"]

let $msDesc := $doc//sourceDesc/msDesc
return local:collate-part-info($msDesc, 0)
