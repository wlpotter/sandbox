xquery version "3.1";

import module namespace functx="http://www.functx.com";

declare namespace srophe="https://srophe.app";
declare default element namespace "http://www.tei-c.org/ns/1.0";

let $sbdColl := collection("C:\Users\anoni\Documents\GitHub\srophe\srophe-app-data\data\persons\tei")
let $gedshColl := collection("C:\Users\anoni\Documents\GitHub\srophe\e-gedsh\data\tei\articles\tei")

let $gedshData := 
  for $art in $gedshColl
  where $art//body/div/ab[@type="idnos"]/note[@type="type"]/text() = "person"
  let $gedshUri := $art//body/div/ab[@type="idnos"]/idno[@type="URI"]/text()
  let $gedshHeadword := $art//body/div/head/text()
  let $gedshInfoBox := normalize-space(string-join($art//body/div/ab[@type="infobox"]//text(), " "))
  let $gedshAbstract := normalize-space(string-join($art//body/div/ab[@type="idnos"]/note[@type="abstract"]//text(), " "))
  let $syriacaUri := $art//body/div/ab[@type="idnos"]/idno[@type="subject"]/text()
  return 
    <rec>
      <gedshUri>{$gedshUri}</gedshUri>
      <gedshHeadword>{$gedshHeadword}</gedshHeadword>
      <gedshInfo>{$gedshInfoBox}</gedshInfo>
      <gedshAbstract>{$gedshAbstract}</gedshAbstract>
      <syriacaUri>{$syriacaUri}</syriacaUri>
    </rec>
    
(: let $syriacaData := 
  for $doc in $sbdColl
  where $doc//listPerson/person/bibl/ptr[@target = ""
  let $sbdUri := $doc//listPerson/person/idno[@type="URI"][1]/text()
  let $sbdHeadwordEn := $doc//listPerson/person/persName[@xml:lang="en"][contains(string(@srophe:tags), "#syriaca-headword")]//text()
  let $sbdHeadwordEn := normalize-space(string-join($sbdHeadwordEn, ""))
  let $sbdHeadwordSyr := $doc//listPerson/person/persName[@xml:lang="syr"][contains(string(@srophe:tags), "#syriaca-headword")]//text()
  let $sbdHeadwordEn := normalize-space(string-join($sbdHeadwordEn, ""))
  let $sbdAbstract := normalize-space(string-join($doc//listPerson/person/note[@type="abstract" and xml:lang="en"]//text(), " "))
  return 
    <rec>
      <syriacaUri>{$sbdUri}</syriacaUri>
      <syriacaHeadwordEnglish>{$sbdHeadwordEn}</syriacaHeadwordEnglish>
      <syriacaHeadwordSyriac>{$sbdHeadwordSyr}</syriacaHeadwordSyriac>
      <syriacaAbstract>{$sbdAbstract}</syriacaAbstract>
    </rec> :)
return csv:serialize(<csv>{$gedshData}</csv>, map{"header": "true"})
(: return $syriacaData :)
