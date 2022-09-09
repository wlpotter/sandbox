xquery version "3.1";

import module namespace mset="http://wlpotter.github.io/ns/mset" at "mset.xqm";
import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:log-report-xml := doc("2022-09-08_authors-test-output_errors-and-successes.xml");

(:
- input info as-is
- error info: code; description; module; location
:)

let $report :=
  for $job in $local:log-report-xml/*/*
  let $inputInfo := 
    for $field in $job/inputInfo/*
    return element {name($field)} {normalize-space(string-join($field//text(), " "))}
  let $jobStatus := if($job/traceback) then "failure" else "success"
  let $jobStatus := element{"status"} {$jobStatus}
  let $errCode := element {"errCode"} {$job/traceback/code/text()}
  let $errDesc := element {"errDesc"} {$job/traceback/description/text()}
  let $errModule := element {"errModule"} {$job/traceback/module/text()}
  let $errLocation := element {"errLocation"} {$job/traceback/location/text()}
  return <job>{$inputInfo, $jobStatus, $errCode, $errDesc, $errModule, $errLocation}</job>
return csv:serialize(<csv>{$report}</csv>, map {"header": "yes"})(: $report :)