xquery version "3.1";

declare default element namespace "http://www.tei-c.org/ns/1.0";


(: language for the tei:respStmt and change logs:)
declare variable $locus-change-log-msg := 
  "ADDED: added missing locus information for msItems";
  
declare variable $locus-respStmt :=
  "Locus information for manuscript items added by";
  
declare variable $form-material-change-log-msg :=
  "CHANGED: updated incorrect form and/or material support designation";
  
declare variable $form-material-respStmt :=
  "Form and material support designations edited by";
  
declare variable $decoration-change-log-msg :=
  "ADDED: added decoNote elements for decorations";
  
declare variable $decoration-respStmt-identified :=
  "Decorations identified and categorized by";
  
declare variable $decoration-respStmt-encoded :=
  "Decoration information encoded by";
  
declare variable $author-uri-change-log-msg :=
  "ADDED: supplied and corrected Syriaca.org URIs for authors";
  
declare variable $author-uri-respStmt-identified :=
  "Syriaca.org URIs for authors checked by";
  
declare variable $author-uri-respStmt-edited :=
  "Syriaca.org URIs for authors edited by";
  
(: A map of the persons first and last names to their editor IDs :)
declare variable $name-id-map :=
map {
  "Alexys Ahn": "aahn",
  "Beth Maczka": "bmaczka",
  "Claire Chen": "cchen",
  "Joseph DAlfonso": "jdalfonso",
  "Justin Arnwine": "jarnwine",
  "Ziyan Zhang": "zzhang"
};


(: Syriaca and BL metadata :)

declare variable $editors-uri-base := "http://syriaca.org/documentation/editors.xml#";
  

(: I/O variables :)

declare variable $path-to-records :=
  "/home/arren/Documents/GitHub/britishLibrary-data/data/tei";
  
declare variable $record-collection :=
  collection($path-to-records);

declare variable $path-to-csv :=
  "/home/arren/Documents/GitHub/sandbox/credit-student-work-on-bl-mss.csv";
  
declare variable $csv :=
  csv:parse(file:read-text($path-to-csv), map {"header": "yes"});  

(: Utility Functions :)

declare function local:create-change-log-from-row($row as node())
as node()*
{
  let $locusChangeLog := 
    if($row/*:locus/text() != "#N/A") then
      element {"change"} {
        attribute {"who"} {$editors-uri-base||$name-id-map($row/*:locus/text())},
        attribute {"when"} {current-date()},
        $locus-change-log-msg
      }
      else ()
  
  let $formMaterialChangeLog := 
    if($row/*:form-material/text() != "#N/A") then
      element {"change"} {
        attribute {"who"} {$editors-uri-base||$name-id-map($row/*:form-material/text())},
        attribute {"when"} {current-date()},
        $form-material-change-log-msg
      }
      else ()
  let $decorationsChangeLog := 
    if($row/*:decoration-encoded/text() != "#N/A") then
      element {"change"} {
        attribute {"who"} {$editors-uri-base||$name-id-map($row/*:decoration-encoded/text())},
        attribute {"when"} {current-date()},
        $decoration-change-log-msg
      }
      else ()
      
  let $authorUriChangeLog := 
    if($row/*:author-tagging-justin/text() != "#N/A") then
      element {"change"} {
        attribute {"who"} {$editors-uri-base||$name-id-map($row/*:author-tagging-justin/text())},
        attribute {"when"} {current-date()},
        $author-uri-change-log-msg
      }
      else ()
      
  return ($locusChangeLog, $formMaterialChangeLog, $decorationsChangeLog, $authorUriChangeLog)
};

declare function local:create-respStmts-from-row($row as node())
as node()*
{
  let $locusResp := 
    if($row/*:locus/text() != "#N/A") then 
      element {"respStmt"} {
        element {"resp"} {$locus-respStmt},
        element {"name"} {
          attribute {"type"} {"person"},
          attribute {"ref"} {$editors-uri-base||$name-id-map($row/*:locus/text())},
          $row/*:locus/text()
        }
      }
    else ()
  
  let $formMaterialResp := 
    if($row/*:form-material/text() != "#N/A") then 
      element {"respStmt"} {
        element {"resp"} {$form-material-respStmt},
        element {"name"} {
          attribute {"type"} {"person"},
          attribute {"ref"} {$editors-uri-base||$name-id-map($row/*:form-material/text())},
          $row/*:form-material/text()
        }
      }
    else ()
  
  let $decorationRespEncoded := 
    if($row/*:decoration-encoded/text() != "#N/A") then 
      element {"respStmt"} {
        element {"resp"} {$decoration-respStmt-encoded},
        element {"name"} {
          attribute {"type"} {"person"},
          attribute {"ref"} {$editors-uri-base||$name-id-map($row/*:decoration-encoded/text())},
          $row/*:decoration-encoded/text()
        }
      }
    else ()
    
  let $decorationRespIdentified := 
    if($row/*:decoration-identified/text() != "#N/A") then 
      element {"respStmt"} {
        element {"resp"} {$decoration-respStmt-identified},
        element {"name"} {
          attribute {"type"} {"person"},
          attribute {"ref"} {$editors-uri-base||$name-id-map($row/*:decoration-identified/text())},
          $row/*:decoration-identified/text()
        }
      }
    else ()
  
  let $authorTaggingEditResp := 
      if($row/*:author-tagging-justin/text() != "#N/A") then 
      element {"respStmt"} {
        element {"resp"} {$author-uri-respStmt-edited},
        element {"name"} {
          attribute {"type"} {"person"},
          attribute {"ref"} {$editors-uri-base||$name-id-map($row/*:author-tagging-justin/text())},
          $row/*:author-tagging-justin/text()
        }
      }
    else ()
    
  let $authorTaggingResp :=
      if($row/*:author-tagging-alexys/text() != "#N/A" and $row/*:author-tagging-joe/text() != "#N/A") then 
      element {"respStmt"} {
        element {"resp"} {$author-uri-respStmt-identified},
        element {"name"} {
          attribute {"type"} {"person"},
          attribute {"ref"} {$editors-uri-base||$name-id-map($row/*:author-tagging-alexys/text())},
          $row/*:author-tagging-alexys/text()
        },
        element {"name"} {
          attribute {"type"} {"person"},
          attribute {"ref"} {$editors-uri-base||$name-id-map($row/*:author-tagging-joe/text())},
          $row/*:author-tagging-joe/text()
        }
      }
    else ()
  
  return ($locusResp, $formMaterialResp, $decorationRespEncoded, $decorationRespIdentified, $authorTaggingEditResp, $authorTaggingResp)
};

declare function local:create-creator-editor-from-row($row as node())
as node()*
{
  if ($row/*:author-tagging-justin/text() = "#N/A") then ()
  else  
    element {"editor"} {
      attribute {"role"} {"creator"},
      attribute {"ref"} {$editors-uri-base||$name-id-map($row/*:author-tagging-justin/text())},
      $row/*:author-tagging-justin/text()
    }
};

(: MAIN SCRIPT :)

for $row in $csv/*:csv/*:record

let $changeLogs := local:create-change-log-from-row($row)
let $respStmts := local:create-respStmts-from-row($row)
let $creatorEditor := local:create-creator-editor-from-row($row)


for $rec in $record-collection
where $rec//msDesc/msIdentifier/idno[@type="URI"]/text() = $row/*:manuscript_uri/text()

return 
  (insert node $respStmts as last into $rec//titleStmt,
  insert node $changeLogs as first into $rec//revisionDesc,
  if($creatorEditor and not($rec//titleStmt/editor[@type="creator"][@ref/string() = $creatorEditor/@ref/string()])) (: if there is a new creator element; and if it won't duplicate what's already in the record :)
  then insert node $creatorEditor before $rec//titleStmt/respStmt[1] else (),
  replace value of node $rec//publicationStmt/date with current-date()
)


(:
- for each row in the csv
  - create the change logs
    - locus if not n/a
    - form-material if not n/a
    - decorations if alexys not n/a
    - author-tagging if justin not n/a
  - create the respStmts
        - locus if not n/a
    - form-material if not n/a
    - decorations if alexys not n/a
    - author-tagging if justin not n/a
  - add the creator editor for Justin if not n/a and if he's not already there
  - find the matching record
  - update the record with change log; respStmt; and creator editor
:)