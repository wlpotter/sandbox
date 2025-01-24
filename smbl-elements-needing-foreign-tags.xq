xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $path-to-repo := "/home/arren/Documents/GitHub/britishLibrary-data/";
declare variable $input-collection := collection($path-to-repo||"data/tei/");

declare variable $langs-to-check := ("en", "la", "it", "und", "fr", "lat");

declare variable $regex-for-non-ascii := "[^\u0000-\u007F]+";

declare variable $regex-for-syriac := "[\u0700-\u074F]+";

declare variable $regex-for-greek-and-coptic := "[\u0370-\u03FF]+";

declare variable $regex-for-arabic := "[\u0600-\u06FF]+";

for $doc in $input-collection
let $fileName := document-uri($doc) => substring-after($path-to-repo)
for $el in $doc//*
(: only look in a set of elements tagged with a language code, without a language code, and only if they have text content :)
where (functx:is-value-in-sequence($el/@xml:lang/string(), $langs-to-check) or $el[not(@xml:lang)]) and $el/text() => string-join() => normalize-space() !=""

(: only return if they have non-ASCII characters :)
where $el/text() => string-join(' ') => normalize-space() => matches($regex-for-arabic, "j")

return $el
(:
- anything with xml:lang="en" or with no tagged xml:lang
:)