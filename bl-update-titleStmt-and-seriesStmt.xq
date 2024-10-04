xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";


declare variable $path-to-repo := "/home/arren/Documents/GitHub/britishLibrary-data";

declare variable $in-coll := collection($path-to-repo||"/data/tei/");

declare variable $series-title := "Syriac Manuscripts in the British Library";

declare variable $series-idno := "https://bl.syriac.uk";

declare variable $editor-uri-base := "https://bl.syriac.uk/documentation/editors.xml";

declare variable $general-editors :=
[
  map {
    "role": "general",
    "id": "dmichelson",
    "name": "D. Michelson"
  },
  map {
    "role": "general",
    "id": "wpotter",
    "name": "W. Potter"
  }
];

declare variable $technical-editors :=
[
  map {
    "role": "technical",
    "id": "dmichelson",
    "name": "D. Michelson"
  },
  map {
    "role": "technical",
    "id": "wpotter",
    "name": "W. Potter"
  },
  map {
    "role": "technical",
    "id": "dschwartz",
    "name": "Daniel L. Schwartz"
  }
];

declare variable $series-stmt :=
element {"seriesStmt"} {
  element {"title"} {
    attribute {"level"} {"s"},
    attribute {"xml:lang"} {"en"},
    $series-title
  },
  for $ed in $general-editors?* return local:create-editor-element($ed),
  for $ed in $technical-editors?* return local:create-editor-element($ed),
  element {"idno"} {
    attribute {"type"} {"URI"},
    $series-idno
  }
  
};

declare variable $author-wright := 
  element {"author"} {
    attribute {"ref"} {$editor-uri-base||"wwright"},
    "William Wright"
    (:<author ref="https://bl.syriac.uk/documentation/editors.xml#wwright">William Wright</author>:)
  };

declare function local:create-editor-element($editorInfo as item()*) 
as node()
{
  element {"editor"} {
    attribute {"role"} {$editorInfo?role},
    attribute {"ref"} {$editor-uri-base||"#"||$editorInfo?id},
    $editorInfo?name
  }
};


for $doc in $in-coll
let $titleStmt := $doc//titleStmt
(: normalize the title string, and supply level and xml:lang attributes :)
let $titleString := $titleStmt/title[@level="a" or not(@level)]/text() => normalize-space()
let $title := 
  element {"title"} {
    attribute {"level"} {"a"},
    attribute {"xml:lang"} {"en"},
    $titleString
  }

(: gather elements that won't change :)
let $sponsor := $titleStmt/sponsor
let $funder := $titleStmt/funder
let $principal := $titleStmt/principal

let $creatorEditors := $titleStmt/editor[@role="creator"]
let $reviewEditors := $titleStmt/editor[@role="review-editor"]

let $respStmts := $titleStmt/respStmt

let $newTitleStmt :=
  element {"titleStmt"}
  {
    $title,
    $sponsor,
    $funder,
    $principal,
    $author-wright,
    $creatorEditors,
    $reviewEditors,
    $respStmts
  }

return $newTitleStmt
(: change this to instead replace $doc//titleStmt and insert seriesStmt into fileDesc after publicationStmt:)