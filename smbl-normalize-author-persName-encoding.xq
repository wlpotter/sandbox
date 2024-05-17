xquery version "3.1";


import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";


declare variable $path-to-repo := "/home/arren/Documents/GitHub/britishLibrary-data/";

declare variable $in-coll := collection($path-to-repo||"data/tei/");

for $doc in $in-coll
for $author in $doc//msItem/editor

return 
  if($author/persName) then ()
  else 
    let $text := $author/text()
    let $normalizedAuthor := 
      element {QName("http://www.tei-c.org/ns/1.0", "author")} {
        $author/@*,
        element {QName("http://www.tei-c.org/ns/1.0", "persName")} {
          attribute {"xml:lang"} {"en"},
          $text
        }
      }
    return replace node $author with $normalizedAuthor
