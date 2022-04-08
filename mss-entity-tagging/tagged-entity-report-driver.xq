import module namespace mset="http://wlpotter.github.io/ns/mset" at "mset.xqm";
import module namespace functx="http://www.functx.com";


declare default element namespace "http://www.tei-c.org/ns/1.0";

let $inColl := collection("C:\Users\anoni\Documents\GitHub\srophe\britishLibrary-data\data\tei\")
return mset:generate-tagged-entity-report($inColl, "author")