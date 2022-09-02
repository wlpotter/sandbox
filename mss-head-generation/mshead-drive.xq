xquery version "3.1";

import module namespace mshead="http://srophe.org/srophe/mshead" at "mshead.xqm";
import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:path-to-repo := "/home/arren/Documents/GitHub/britishLibrary-data/";

declare variable $local:input-collection := collection($local:path-to-repo||"/data/tei/");

for $doc in $local:input-collection
for $ms in $doc//*[name() = "msDesc" or name() = "msPart"]
return insert node mshead:compose-head-element($ms) after $ms/msIdentifier
(: return (
  try{
  mshead:compose-head-element($ms)
}
catch*
{
  <error>
  <recordInfo>
    <docUri>{document-uri($doc)}</docUri>
    <msUri>{$ms/msIdentifier/idno/text()}</msUri>
  </recordInfo>
  <queryInfo>
  <code>{$err:code}</code>
  <desc>{$err:description}</desc>
  <module>{$err:module}</module>
  <lineNumber>{$err:line-number}</lineNumber>
  <columnNumber>{$err:column-number}</columnNumber>
  </queryInfo>
  </error>
},
  for $part in $ms//msPart
  return 
    try{
 mshead:compose-head-element($part)
}
catch*
{
  <error>
  <recordInfo>
    <docUri>{document-uri($doc)}</docUri>
    <msUri>{$ms/msIdentifier/idno/text()}</msUri>
  </recordInfo>
  <queryInfo>
  <code>{$err:code}</code>
  <desc>{$err:description}</desc>
  <module>{$err:module}</module>
  <lineNumber>{$err:line-number}</lineNumber>
  <columnNumber>{$err:column-number}</columnNumber>
  </queryInfo>
  </error>
}
) :)
