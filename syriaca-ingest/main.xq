xquery version "3.1";
import module namespace functx = "http://www.functx.com" at "https://www.datypic.com/xq/functx-1.0.1-doc.xq";
import module namespace load="http://wlpotter.github.io/ns/syriaca-ingest/load" at "/home/arren/Documents/GitHub/sandbox/syriaca-ingest/modules/load.xqm";
import module namespace process="http://wlpotter.github.io/ns/syriaca-ingest/process" at "/home/arren/Documents/GitHub/sandbox/syriaca-ingest/modules/process.xqm";
import module namespace ingest="http://wlpotter.github.io/ns/syriaca-ingest/ingest" at "/home/arren/Documents/GitHub/sandbox/syriaca-ingest/modules/ingest.xqm";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare namespace srophe = "https://srophe.app";
declare option output:omit-xml-declaration "no";

(: EXTERNAL VARIABLES :)
declare variable $ingest-data-path external; (: could rework to have this also allow a path to an xquery that is set up to parse data into an ingestible format? :)

declare variable $ingest-data-type external := "xml";

declare variable $ingest-data := load:load-data-for-ingest($ingest-data-path, $ingest-data-type);

declare variable $entity-type external;

declare variable $path-to-existing-data external;

declare variable $existing-data := collection($path-to-existing-data);

declare variable $options_string external;

declare variable $options := json:parse($options_string, map {"format": "xquery"});

let $processedData := process:process-ingest-data($ingest-data, $options?process)
return ingest:update-existing-records-with-new-data($existing-data, $processedData, $entity-type)