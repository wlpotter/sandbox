xquery version "3.0";
declare default element namespace "http://www.tei-c.org/ns/1.0";

import module namespace functx = 'http://www.functx.com';


let $dataUri := "C:\Users\anoni\Desktop\CAESAREA-FILES\"
let $dataUri := fn:replace($dataUri, "\\", "/")
for $doc in fn:collection($dataUri)
  where fn:count($doc//teiHeader/encodingDesc/classDecl/taxonomy) > 2
  let $newClassDecl := element classDecl {$doc//$doc//teiHeader/encodingDesc/classDecl/taxonomy[1], $doc//teiHeader/encodingDesc/classDecl/taxonomy[2]}
  return replace node $doc//teiHeader/encodingDesc/classDecl with $newClassDecl


