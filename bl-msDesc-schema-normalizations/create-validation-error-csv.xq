xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.oxygenxml.com/ns/report";

declare variable $local:path-to-repo := "/home/arren/Documents/GitHub/sandbox/bl-msDesc-schema-normalizations/";

declare variable $local:errors-doc := doc($local:path-to-repo||"msDesc-consolidated-validation-errors_2024-03-29.xml");

declare variable $local:path-to-bl-data-repo := "/home/arren/Documents/GitHub/britishLibrary-data";

let $errors :=
  for $error at $i in $local:errors-doc/report/incident
  (: where $i = 100 :)
  let $engine := $error/engine
  let $severity := $error/severity
  let $description := $error/description
  let $systemId := element {"systemId"} {replace($error/systemID/text(), $local:path-to-bl-data-repo, "")}
  let $validationFile := element {"validationFile"} {replace($error/operationDescription/mainValidationFile/text(), $local:path-to-bl-data-repo, "")}
  let $locationStart := element {"locationStart"} {$error/location/start/line/text()||":"||$error/location/start/column/text()}
  let $locationEnd := element {"locationEnd"} {$error/location/end/line/text()||":"||$error/location/end/column/text()}
  
  return element {$error/name()} {
    $engine,
    $severity,
    $description,
    $systemId,
    $validationFile,
    $locationStart,
    $locationEnd
  }
(: return $errors :)
let $csv := csv:serialize(<csv>{$errors}</csv>, map {"header": "yes"})
return file:write($local:path-to-repo||"msDesc-consolidated-validation-errors_2024-03-29.csv", $csv)