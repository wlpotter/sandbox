xquery version "3.0";
declare default element namespace "http://www.tei-c.org/ns/1.0";

import module namespace functx = 'http://www.functx.com';

let $folderUri := "C:\Users\anoni\Desktop\CAESAREA-FILES\Inbox\"
let $folderUri := fn:replace($folderUri, "\\", "/")
let $inCollection := fn:collection($folderUri)

let $outputFolderUri := "C:\Users\anoni\Desktop\CAESAREA-FILES\"
let $outputFolderUri := fn:replace($outputFolderUri, "\\", "/")
for $doc in $inCollection
  let $uriAsEntered := $doc//fileDesc/publicationStmt/idno[@type="URI"]/text()
  let $fileName := fn:substring-after(fn:document-uri($doc), $folderUri)
  let $uriFromFileName := functx:get-matches($fileName, "\d+-")[1]
  let $uriFromFileName := fn:substring-before($uriFromFileName, "-")
  
  let $newUri := <idno type="URI">{$uriFromFileName}</idno>
  
  return if (number($uriFromFileName) > 214) then 
    (replace node $doc//fileDesc/publicationStmt/idno[@type="URI"] with $newUri, fn:put($doc, $outputFolderUri||$uriFromFileName||".xml"))
  