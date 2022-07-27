xquery version "3.1";

import module namespace mshead="http://srophe.org/srophe/mshead" at "mshead.xqm";
import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

for $doc in collection("C:\Users\anoni\Documents\GitHub\srophe\britishLibrary-data\data\tei")
where $doc//msIdentifier/idno/text() = "http://syriaca.org/manuscript/652"
let $msDesc := $doc//msDesc
return mshead:get-wright-taxonomy-value-from-profileDesc($doc//msPart[20])
