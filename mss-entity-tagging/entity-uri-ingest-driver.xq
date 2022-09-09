xquery version "3.1";

import module namespace mset="http://wlpotter.github.io/ns/mset" at "mset.xqm";
import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:path-to-repo := "/home/arren/Documents/GitHub/britishLibrary-data/";
declare variable $local:input-collection := collection($local:path-to-repo||"data/tei/");
declare variable $local:path-to-ingest-csv := "/home/arren/Documents/GitHub/sandbox/mss-entity-tagging/test_author-ingest.csv";
declare variable $local:entity-uri-ingest-doc := 
  mset:parse-csv($local:path-to-ingest-csv);
declare variable $local:entity-type := "author";
declare variable $local:uri-field-name := "author_uri_possibility1";

for $doc in $local:input-collection
(: where $doc//msDesc/msIdentifier/idno/text() = "http://syriaca.org/manuscript/256" :)
let $msUri := $doc//msDesc/msIdentifier/idno/text()
let $rows := mset:get-entity-rows-by-manuscript-uri($msUri, $local:entity-uri-ingest-doc)
for $row in $rows
  let $inputInfo :=
    <inputInfo>
        <fileLocation>{$local:path-to-repo||$row/*:ms_record_file_location/text()}</fileLocation>
        <msUri>{$row/*:ms_level_uri/text()}</msUri>
        <nodePath>{$row/*:unique_xpath/text()}</nodePath>
        <nodePosition>{$row/*[contains(name(), "position_in_sequence")]/text()}</nodePosition>
        <entityTextNode>{$row/*[name() = $local:entity-type||"_text_node"]/text()}</entityTextNode>
        <currentUri>{$row/*[name() = $local:entity-type||"_uri_current"]/text()}</currentUri>
        <updatedUri>{$row/*[name() = $local:uri-field-name]/text()}</updatedUri>
        <targetedNode>{mset:dynamic-path($doc, $row/*:unique_xpath/text())}</targetedNode>
      </inputInfo>
  return try {(mset:update-entity-uri($doc, $row), update:output(<success>{$inputInfo}</success>))}
  catch * {
    let $error := 
    <error>
      <traceback>
        <code>{$err:code}</code>
        <description>{$err:description}</description>
        <value>{$err:value}</value>
        <module>{$err:module}</module>
        <location>{$err:line-number||":"||$err:column-number}</location>
        <additional>{$err:additional}</additional>
      </traceback>
      {$inputInfo}
    </error>
    return update:output($error)
  }