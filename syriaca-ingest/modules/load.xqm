xquery version "3.1";

module namespace load="http://wlpotter.github.io/ns/syriaca-ingest/load";

(:
TBD:
- CSV delimiter...
:)
declare function load:load-data-for-ingest($ingest-data-path as xs:string, 
                                            $ingest-data-type as xs:string)
                                        as item()
{
    if($ingest-data-type = "csv") then
        csv:doc($ingest-data-path)
    else
        doc($ingest-data-path)
};