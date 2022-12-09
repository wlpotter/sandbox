xquery version "3.1";


declare variable $local:path-to-file := "/home/arren/Documents/GitHub/sandbox/cbsc-syriaca/2022-12-02_syriaca-to-cbsc-potential-matches.xml";

declare variable $local:in-doc := doc($local:path-to-file);

let $rows :=
  for $bibl in $local:in-doc/root/row
  
  let $hasPossibleMatch := $bibl/@hasMatch/string()
  let $syriacaBiblUri := $bibl/syriacaBiblUri
  let $syriacaZoteroUri := $bibl/syriacaZoteroUri
  
  let $emptyFields := 
    (
      element {"correctedCBSCMatch"} {},
      element {"notes"} {},
      element {"checkedBy"} {},
      element {"status"} {"not checked"},
      element {"hasPossibleMatch"} {$hasPossibleMatch}
    )
  let $noMatchFields := 
    (
      element {"cbscZoteroUri"} {},
      element {"syriaca_year"} {},
      element {"cbsc_year"} {},
      element {"syriaca_authors-editors"} {},
      element {"cbsc_authors-editors"} {},
      element {"syriaca_title"} {},
      element {"cbsc_title"} {},
      element {"match-type"} {"5. no match"},
      $emptyFields,
      element {"potentialMatchNumber"} {1}
    )
  
  return 
    if($hasPossibleMatch = "false") then 
      element {"row"} {$syriacaBiblUri, $syriacaZoteroUri, $noMatchFields}
    else
      for $result at $i in $bibl/result
      return
        element {"row"} {
          $syriacaBiblUri,
          $syriacaZoteroUri,
          $result/*,
          $emptyFields,
          element {"potentialMatchNumber"} {$i}
        }
return csv:serialize(<scv>{$rows}</scv>, map {"header": "yes"})
