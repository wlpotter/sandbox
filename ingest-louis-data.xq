xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace output = 'http://www.w3.org/2010/xslt-xquery-serialization';

declare option output:omit-xml-declaration 'no';
declare option output:indent 'yes';

declare variable $path-to-repo := "/home/arren/Documents/GitHub/syriaca-data/";
declare variable $places := collection($path-to-repo||"data/places/tei/");

declare variable $path-to-csv := "/home/arren/Downloads/Syriac Gazetteer Asia Places - Main.csv";
declare variable $csv := csv:doc($path-to-csv, map {"header": "yes"});

declare variable $resp-stmts := {
  "abstract": "Abstract added by",
  "placeNames": "Review of Chinese character place names from WikiData by"
};

declare variable $editor-info := {
  "uri": "https://syriaca.org/documentation/editors.xml#lwu",
  "name": "Louis Wu"
};

declare variable $change-log-messages := {
  "abstract": "ADDED: place abstract",
  "placeNames": "ADDED: Chinese character place names from WikiData"
};

declare variable $cbss-uri-for-wikidata := "http://syriaca.org/cbss/WE7UFM6B";

declare function local:get-source-attr($row as node(), $lastBiblId as xs:integer, $placeId as xs:string)
as xs:string? {
  let $sourceAttr :=
    for $source at $i in $row/*[name() = "Source_Cited_1" or name() = "Source_Cited_2" or name() = "Source_Cited_3"]
    where normalize-space($source/text()) != ""
    return "#bib"||$placeId||"-"||$lastBiblId + $i
 return string-join($sourceAttr, " ")
} ;

declare function local:create-new-bib-elements($row as node(), $lastBiblId as xs:integer, $placeId as xs:string, $wikidataUri as xs:string?)
as node()* {
  let $abstractBibls :=
    for $source at $i in $row/*[name() = "Source_Cited_1" or name() = "Source_Cited_2" or name() = "Source_Cited_3"]
    where $source/text() => normalize-space() != ""
    return element {"bibl"} {
      attribute {"xml:id"} {"bib"||$placeId||"-"||$lastBiblId + $i},
      element {"ptr"} {
        attribute {"target"} {$source/text() => normalize-space()}
      },
      if($row/*[name() = "Source_Cited_"||$i||"_ch"]/text() => normalize-space() != "") then
        element {"citedRange"} {
          attribute {"unit"} {"chapter"}, (: TODO: handle non-page ones...:)
          $row/*[name() = "Source_Cited_"||$i||"_ch"]/text() => normalize-space()
        }
      else(),
      if($row/*[name() = "Source_Cited_"||$i||"_p"]/text() => normalize-space() != "") then
        element {"citedRange"} {
          attribute {"unit"} {"p"}, (: TODO: handle non-page ones...:)
          $row/*[name() = "Source_Cited_"||$i||"_p"]/text() => normalize-space()
        }
      else()
    }
    
 let $wikidataBibl := if($wikidataUri) then 
   element {"bibl"} {
      attribute {"xml:id"} {"bib"||$placeId||"-"||$lastBiblId + max((count($abstractBibls), 0)) + 1},
      element {"ptr"} {
        attribute {"target"} {$cbss-uri-for-wikidata}
      },
      element {"citedRange"} {
        attribute {"unit"} {"entry"},
        attribute {"target"} {$wikidataUri},
        $wikidataUri
      }
    }
 return ($abstractBibls, $wikidataBibl)
};

for $row in $csv/*:csv/*:record
let $uri := $row/*:Syriaca_URI/text() 
let $placeId := substring-after($uri, "syriaca.org/place/")
where $uri != ""

let $place := 
  for $p in $places
  where $p//publicationStmt/idno[@type="URI"]/text() => contains($uri)
  return $p

let $biblIdSeq :=
  for $bib in $place//listPlace/place/bibl
  return $bib/@xml:id/string() => substring-after("-") => xs:integer()

let $lastBiblId := xs:integer(max(($biblIdSeq, 1)))

(: Ignore abstracts if no new one or if there is already an abstract, which we'll handle manually :)
let $newAbstract := $row/*:Revised_Abstract/text() => normalize-space()
let $newAbstract := if ($newAbstract != "" and not($place//listPlace/place/desc[@type="abstract"])) then
  let $corresp := $place//seriesStmt/idno/text() => string-join(" ") (: get from seriesStmt if no other abstract, but what if there are? :)
  let $sourceAttr := local:get-source-attr($row, $lastBiblId, $placeId) 
  return element {"desc"} {
    attribute {"type"} {"abstract"},
    attribute {"corresp"} {$corresp}, 
    attribute {"source"} {$sourceAttr}, 
    attribute {"xml:lang"} {"en"},
    $newAbstract
  }
   else ()

(: Add the Wikidata idno if it doesn't exist yet :)
let $wikidataUri := if($row/*:Wikidata_ID != "") then "http://www.wikidata.org/entity/"||$row/*:Wikidata_ID/text() => normalize-space() else ''
let $wikidataIdno := if($wikidataUri != "") then 
  element {"idno"} {
    attribute {"type"} {"URI"},
    $wikidataUri
  }
  else ()

let $newBibls := local:create-new-bib-elements($row, $lastBiblId, $placeId, $wikidataUri)

let $placeIdSeq :=
  for $name in $place//listPlace/place/placeName
  return $name/@xml:id/string() => substring-after("-") => xs:integer()
let $lastPlaceId := xs:integer(max(($placeIdSeq, 1)))

(: Collate the languages into a list, with the language code following the @ :)
let $newNames :=
  for $langcode in ("zh-hans", "zh-hant", "zh")
  for $name in $row/*[contains(name(), "_"||$langcode||"_")]/text() => tokenize("\n")
  where normalize-space($name) != ""
  return normalize-space($name)||"@"||$langcode
  
let $placeNames :=
  for $name at $i in $newNames
  where $name != ""
  return element {"placeName"} {
    attribute {"xml:id"} {"place"||$placeId||"-"||$lastPlaceId + $i},
    attribute {"xml:lang"} {tokenize($name, "@")[2]},
    attribute {"source"} {"#"||$newBibls[ptr/@target/string() = $cbss-uri-for-wikidata]/@xml:id/string()},
    tokenize($name, "@")[1]
  }


let $editor := element {"editor"} {
  attribute {"role"} {if($newAbstract) then "creator" else "contributor"},
  attribute {"ref"} {$editor-info?uri},
  $editor-info?name
}

let $respName := element {"name"} {
  attribute {"ref"} {$editor-info?uri},
  $editor-info?name
}

let $respStmts := (
  if($newAbstract) then element {"respStmt"} {
    element {"resp"} {$resp-stmts?abstract},
    $respName
  } else (),
  if($placeNames) then element {"respStmt"} {
    element {"resp"} {$resp-stmts?placeNames},
    $respName
  } else ()
)

let $changeLogs :=  (
  if($newAbstract) then element {"change"} {
    attribute {"who"} {$editor-info?uri},
    attribute {"when"} {current-date()},
    $change-log-messages?abstract
  },
  if($placeNames) then element {"change"} {
    attribute {"who"} {$editor-info?uri},
    attribute {"when"} {current-date()},
    $change-log-messages?placeNames
  }
)

(: Only update where there is changed data :)
where $newAbstract or $placeNames or $wikidataIdno

return (
  insert node $editor after $place//titleStmt/editor[@role = $editor/@role][last()],
  insert node $respStmts before $place//titleStmt/respStmt[1],
  replace value of node $place//publicationStmt/date with current-date(),
 insert node $changeLogs before $place//revisionDesc/change[1],
 insert node ($placeNames, $newAbstract) after $place//listPlace/place/placeName[last()],
 insert node $wikidataIdno after $place//listPlace/place/idno[@type="URI"][last()],
 insert node $newBibls after $place//listPlace/place/bibl[last()]
)