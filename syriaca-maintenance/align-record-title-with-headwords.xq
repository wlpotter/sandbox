xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare namespace srophe="https://srophe.app";
declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace output = 'http://www.w3.org/2010/xslt-xquery-serialization';

declare option output:omit-xml-declaration 'no';
declare option output:indent 'yes';

declare function local:clean-descendant-text($element as node()?)
as xs:string? {
  $element//text()
    => string-join(" ")
    => normalize-space()
};

declare variable $path-to-repo := "/home/arren/Documents/GitHub/syriaca-data/";
declare variable $works := collection($path-to-repo||"data/works/tei/");
declare variable $places := collection($path-to-repo||"data/places/tei/");
declare variable $persons := collection($path-to-repo||"data/persons/tei/");

(:
NOTE: headwordPath is relative to the body element.
TBD: Documentation
:)
declare variable $entity-config := map {
  "person": {
    "headwordPath": "listPerson/*/persName",
    "collection": $persons
  },
  "place": {
    "headwordPath": "listPlace/place/placeName",
    "collection": $places
  },
  "work": {
    "headwordPath": "bibl/title",
    "collection": $works
  }
};

for $entity in $entity-config?person
for $doc in $entity?collection
let $labels := functx:dynamic-path($doc//body, $entity?headwordPath)
let $headwords := $labels[contains(@srophe:tags, "syriaca-headword")]

let $enHeadword := local:clean-descendant-text($headwords[@xml:lang="en"])
let $syrHeadword := local:clean-descendant-text($headwords[@xml:lang="syr"])
return 
    element {"title"} {
      attribute {"level"} {"a"},
      attribute {"xml:lang"} {"en"},
      try {
      if($syrHeadword != "") then (
        $enHeadword||" — ",
        element {"foreign"} {
          attribute {"xml:lang"} {"syr"},
          $syrHeadword
        }
      )
      else $enHeadword
    }catch * {
    document-uri($doc)
  }
 }