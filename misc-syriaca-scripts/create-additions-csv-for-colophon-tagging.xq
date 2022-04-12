declare default element namespace "http://www.tei-c.org/ns/1.0";

let $inColl := collection("C:\Users\anoni\Documents\GitHub\srophe\britishLibrary-data\data\tei\")
let $adminMetadata := (
    element {"status"} {"pending"},
    element {"asignee"} {},
    element {"syriaca_notes"} {}
  )
let $additionList :=
  for $doc in $inColl
  let $recordFileLocation := element {"ms_record_file_location"} {substring-after(document-uri($doc), "britishLibrary-data")}
  let $msUri := element {"ms_level_uri"} {$doc//msDesc/msIdentifier/idno[@type="URI"]/text()}
  for $addition in $doc//msDesc//physDesc/additions/list/item
  let $xmlId := element {"addition_xml-id"} {$addition/@xml:id/string()}
  let $locusStart := element{"locus_start"} {$addition/locus/@from/string()}
  let $additionText := element {"addition_text_node"} {normalize-space(string-join($addition//text(), " "))}
  let $isColophon := element {"is_colophon"} {}
  return element {"addition"} {$recordFileLocation, $msUri, $xmlId, $locusStart, $additionText, $isColophon, $adminMetadata}
return csv:serialize(<csv>{$additionList}</csv>, map {"header": "true"})