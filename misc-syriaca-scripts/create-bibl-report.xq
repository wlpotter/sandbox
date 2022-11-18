(:
ms generation of all the bibls.

1. find all the bibls that are in an msItem (i.e., in msContents)
2. get the unique ID of the containing msItem
3. get the distinct xpath of the element, including position
4. return the text node and whether or not there is a 

:)
import module namespace msParts="http://srophe.org/srophe/msParts" at "/home/arren/Documents/GitHub/wright-catalogue/modules/msParts.xqm";
import module namespace mss="http://srophe.org/srophe/mss" at "/home/arren/Documents/GitHub/wright-catalogue/modules/mss.xqm";
import module namespace strfy="http://wlpotter.github.io/ns/strfy" at "https://raw.githubusercontent.com/wlpotter/xquery-utility-modules/main/stringify.xqm";
import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $local:input-collection :=
  collection("/home/arren/Documents/GitHub/britishLibrary-data/data/tei/");

declare function local:title-author-string-from-item($item as node())
as xs:string
{
  let $title := normalize-space(string-join($item/title[1]//text(), " "))
  let $author := for $a in $item/author return normalize-space(string-join($a//text(), " "))
  let $authString := if(not(empty($author))) then string-join($author, ", ")||". " else ()
  return $authString||$title
};

let $results := 
  for $doc in $local:input-collection
  let $msLevelUri := $doc//msDesc/msIdentifier/idno[@type="URI"]/text()
  let $bibs :=
    for $bib in $doc//msContents//bibl
    let $containingItem := $bib/ancestor::msItem[1]
    let $itemContentString := local:title-author-string-from-item($containingItem)
    let $uniquePath := functx:path-to-node-with-pos($bib)
    let $parentName := $bib/../name()
    let $biblText := normalize-space(string-join($bib//text(), " "))
    let $ptrTarget := $bib/ptr/@target/string()
    let $stringifiedBibl := strfy:stringify-node($bib, map {"normalize-space": true ()})
  (:
  - bibl text nodes
  - if there's a ptr get the target to test
  
  :)
    
    (: where $bib//msIdentifier or $bib//altIdentifier or $bib//idno :)
    return 
    try{
      element {"hit"} {
        element {"docId"} {document-uri($doc)},
        element {"msLevelUri"} {$msLevelUri},
        element {"msItemId"} {$containingItem/@xml:id/string()},
        element {"distinctPath"} {$uniquePath},
        element {"parentName"} {$parentName},
        element {"textOfBiblNode"} {$biblText},
        element {"biblPtrUri"} {$ptrTarget},
        element {"biblNodeAsString"} {$stringifiedBibl},
        element {"msItemContents"} {$itemContentString}
      }
    }
    catch * {
       <error>
      <traceback>
        <code>{$err:code}</code>
        <description>{$err:description}</description>
        <value>{$err:value}</value>
        <module>{$err:module}</module>
        <location>{$err:line-number||":"||$err:column-number}</location>
        <additional>{$err:additional}</additional>
      </traceback>
      <docId>{document-uri($doc)}</docId>
      <msItemId>{$containingItem/@xml:id/string()}</msItemId>
    </error>
    }
        
  return $bibs
return csv:serialize(<csv>{$results}</csv>, map {"header": "yes"})
  