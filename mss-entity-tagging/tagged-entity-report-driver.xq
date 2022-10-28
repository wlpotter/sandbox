import module namespace mset="http://wlpotter.github.io/ns/mset" at "mset.xqm";
import module namespace functx="http://www.functx.com";


declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:path-to-repo := "/home/arren/Documents/GitHub/britishLibrary-data/";
declare variable $local:input-collection := collection($local:path-to-repo||"data/tei/");

let $report := <report>{mset:generate-tagged-entity-report($local:input-collection, "author")}</report>
(: return $report :)
return csv:serialize($report, map {"header": "true"})