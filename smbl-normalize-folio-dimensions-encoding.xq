xquery version "3.1";


import module namespace functx="http://www.functx.com";

declare default element namespace "http://www.tei-c.org/ns/1.0";


declare variable $path-to-repo := "/home/arren/Documents/GitHub/britishLibrary-data/";

declare variable $in-coll := collection($path-to-repo||"data/tei/");

(:
Current:

<dimensions type="leaf" unit="in">
  <height>
    <measure type="height" quantity="9.875" unit="in">9 7/8</measure>
  </height>
  <width>
    <measure type="width" quantity="6.625" unit="in">6 5/8</measure>
  </width>
</dimensions>
:)

(:
Expected:
<dimensions type="leaf" unit="inch">
  <height quantity="9.875" >9 7/8</height>
  <width quantity="6.625">6 5/8</width>
</dimensions>
:)

(:
- substring-before-if-contains " in."
:)
for $doc in $in-coll
for $dim in $doc//dimensions[@type="leaf"]

let $heightText := $dim/height/measure/text() => functx:substring-before-if-contains(" in")
let $widthText :=  $dim/width/measure/text() => functx:substring-before-if-contains(" in")

let $normalizedDim :=
  element {QName("http://www.tei-c.org/ns/1.0", "dimensions")} {
    $dim/@type,
    attribute {"unit"} {"inch"},
    element {QName("http://www.tei-c.org/ns/1.0", "height")} {
      $dim/height/measure/@quantity,
      $heightText
    },
    element {QName("http://www.tei-c.org/ns/1.0","width")} {
      $dim/width/measure/@quantity,
      $widthText
    }
    
  }
return try {replace node $dim with $normalizedDim} catch * {update:output(document-uri($doc))}