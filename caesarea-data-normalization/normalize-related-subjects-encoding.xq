declare default element namespace "http://www.tei-c.org/ns/1.0";

let $coll := collection("C:\Users\anoni\Documents\GitHub\srophe\caesarea-data\data\testimonia\tei\")

for $doc in $coll
(: where $doc//body/ab[@type="identifier"]/idno/text() = "https://caesarea-maritima.org/testimonia/276" :)
let $updatedNotes := 
  for $note in $doc//text/body/note
  let $relatedSubjects :=
    (
    $note/p/text(),
    $note/p/list/item/p/text(),
    $note/list/item/text(),
    $note/p/list/item/text(),
    $note/list/item/list/item/text(),
    $note/list/item/p/text(),
    $note/p/hi/text(),
    $note/p/hi/hi/text(),
    $note/hi/text(),
    $note/text()
    )
  return element {node-name($note)} {$note/@*,
    for $subject in $relatedSubjects
    where normalize-space($subject) != ""
    return element {QName("http://www.tei-c.org/ns/1.0", "p")} {normalize-space($subject)}
  }
return 
  (delete node $doc//text/body/note,
   insert node $updatedNotes as last into $doc//text/body)
