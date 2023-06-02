xquery version "3.1";


declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:in-coll := collection("/home/arren/Documents/GitHub/caesarea-data/data/testimonia/tei");

declare variable $local:related-subjects-csv :=
  let $path := "/home/arren/Documents/GitHub/sandbox/c-m-scripts/update-testimonia-related-subjects/test-related-subjects-ingest.csv"
  let $file := file:read-text($path)
  return csv:parse($file, map {"header": "yes"});

declare variable $local:related-subjs-config :=
  (
    map {
    "id": "texts",
    "type": "related-texts",
    "desc": "Related Texts",
    "uri-column": "texts.uri",
    "text-node-column": "texts.normalized"
  },
      map {
    "id": "prosopography",
    "type": "prosopography",
    "desc": "Prosopography",
    "uri-column": "prosopography.uri",
    "text-node-column": "prosopography.normalized"
  },
      map {
    "id": "geography",
    "type": "geography",
    "desc": "Geography",
    "uri-column": "geography.uri",
    "text-node-column": "geography.normalized"
  },
      map {
    "id": "themes",
    "type": "themes",
    "desc": "Themes",
    "uri-column": "",
    "text-node-column": "themes.normalized"
  }
);

for $doc in $local:in-coll
let $doc-uri := $doc//body/ab[@type="identifier"]/idno/text()
(: where $doc-uri = "https://caesarea-maritima.org/testimonia/1" :)
let $subjectsToIngest := $local:related-subjects-csv/*:csv/*:record[*:uri/text() = $doc-uri]

let $subjectListRefs :=
  for $subjType in $local:related-subjs-config
  let $subjectRefs :=
    for $subj in $subjectsToIngest[*:subjectType/text() = $subjType("type")]
    return element {"ref"} {
     attribute {"target"} {$subj/*[name() = $subjType("uri-column")]/text()},
     $subj/*[name() = $subjType("text-node-column")]/text()
    }
  return
   element {"listRelation"}
   {
     attribute {"type"} {$subjType("type")},
     element {"desc"} {$subjType("desc")},
     $subjectRefs
  }
(:

LEFT TO DO:
handle edge cases of "#N/A" in the text node. Raise an exception? Ignore?
replace this return with xquery update expressions:
- delete the notes in the body
- insert the listRelations as last into body
:)
return <rec uri="{$doc-uri}">{$subjectListRefs}</rec>