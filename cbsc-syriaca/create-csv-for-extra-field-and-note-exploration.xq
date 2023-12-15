xquery version "3.1";

import module namespace functx="http://www.functx.com";


declare variable $in-json :=
  let $pathToFile := "/home/arren/CBSS_json-export.json"
  let $file := file:read-text($pathToFile)
  return json:parse($file);

declare variable $ENDNOTE-IMPORT-PREAMBLE := "The following values have no corresponding Zotero field:&lt;br/&gt;";


(: takes a sequence of key-value pairs as strings, separated by `: `.
:  returns an xml sequence:
: <pair> 
:   <key>Key</key>
:   <val>Value</val>
: </pair>
:)
declare function local:parse-key-value-sequence($keyValuePairs as xs:string*)
as item()*
{
  for $pair in $keyValuePairs
  let $key := substring-before($pair, ":")
  let $val := substring($pair, string-length($key) + 3)
  return 
  <pair>
    <key>{$key}</key>
    <val>{$val}</val>
  </pair>
};

(: Takes a series of JSON-derived notes of the form 
<_ type="object">
  <key>ZMZCSEBK</key>
  <version type="number">69</version>
  <itemType>note</itemType>
  <parentItem>3TYAXRG6</parentItem>
  <note>The following values have no corresponding Zotero field:&lt;br/&gt;section: 295-300</note>
  <tags type="array">
    <_ type="object">
      <tag>_EndnoteXML import</tag>
    </_>
  </tags>
  <relations type="object"/>
  <dateAdded>2022-11-18T14:30:35Z</dateAdded>
  <dateModified>2022-11-18T14:30:35Z</dateModified>
  <uri>http://zotero.org/groups/4861694/items/ZMZCSEBK</uri>
</_>

and processes them into one-or-more key-value pair records
:)
declare function local:process-endnote-import-notes($endNoteImportNotes as node()*, $parentUri as xs:string)
as item()*
{
  for $note in $endNoteImportNotes
  let $noteString := $note/note/text() => substring-after($ENDNOTE-IMPORT-PREAMBLE)
  let $keyVals := functx:lines($noteString)
  let $pairs := local:parse-key-value-sequence($keyVals)
  return local:add-metadata-to-key-val-pairs($pairs, "endnoteimport", $note/key/text(), $parentUri)
};

declare function local:process-additional-notes($notes as item()*, $parentUri as xs:string)
{
  for $note in $notes
  let $noteString := "note: "||$note/note/text()
  let $pairs := local:parse-key-value-sequence($noteString)
  return local:add-metadata-to-key-val-pairs($pairs, "note", $note/key/text(), $parentUri)   
};

declare function local:add-metadata-to-key-val-pairs($pairs as item()*, $type as xs:string, $localIdBase as xs:string, $parentUri as xs:string)
{
  for $p at $i in $pairs
  let $localId := $localIdBase||replace($p/key/text(), "\s+", "_")||"_"||$i
  return element {$p/name()} {
    element {"localId"} {$localId},
    element {"type"} {$type},
    $p/*,
    element {"parentURI"} {$parentUri}
  }
};

let $rows :=
  for $item in $in-json/json/items/*
  
  let $itemUri := $item/uri/text()
  let $itemKey := $item/itemKey/text()
  
  (: take the extra field and turn it into :)
  let $extra := $item/extra/text()
  let $extra := $extra => functx:lines()
  
  (: parse the extra field into a sequence of key-value pairs :)
  let $extraPairs := local:parse-key-value-sequence($extra)
  let $extraPairs := local:add-metadata-to-key-val-pairs($extraPairs, "extra", $itemKey, $itemUri)
  
  
  (: Process any notes, pulling out the ones that are endnote import problems :)
  let $notes := $item/notes/*
  let $endNoteImportNotes := $notes[tags//tag/text() = "_EndnoteXML import"]
  let $additionalNotes := $notes[not(tags//tag/text() = "_EndnoteXML import")]
  
  (: process the import notes that came from End Note :)
  let $endNotePairs := local:process-endnote-import-notes($endNoteImportNotes, $itemUri)
  
  let $additionalNotePairs := local:process-additional-notes($additionalNotes, $itemUri)
  
  return ($extraPairs, $endNotePairs, $additionalNotePairs)
return csv:serialize(<csv>{$rows}</csv>, map {"header": "yes"})