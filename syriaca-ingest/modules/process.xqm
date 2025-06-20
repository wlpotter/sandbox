xquery version "3.1";


module namespace process="http://wlpotter.github.io/ns/syriaca-ingest/process";
import module namespace functx = "http://www.functx.com" at "https://www.datypic.com/xq/functx-1.0.1-doc.xq";

declare function process:process-ingest-data($ingest-data as item()+, $options as map(*)? := {})
as item()+ {
    
    (:TBD: switch to use xquery:evaluate to call a separate xquery that's in the options processor parameter? :)
    switch($options?processor)
    case("Syriac World") return map:merge(process:process-syriac-world-data($ingest-data, $options))
    default return()
};


declare function process:process-syriac-world-data($data as item(), $options as map(*)? := {})
as item()+ {
    let $otherData := process:create-other-data($options?other_data)

    let $bibData := $otherData?bib_info

    for $rec in $data/*:list/*:record

    let $uri := "http://" || $rec/*:Syriaca_URI/*:label/text()
    
    let $sources := process:collate-syriac-world-bib-info($rec/*:Syriaca_URI/*:label/text(), $bibData)
    let $mapBibls := process:create-bibl-map($sources?distinct_maps_range, "http://syriaca.org/cbss/RUENEDMU", 0, "map")
    let $indexBibls := process:create-bibl-map($sources?distinct_index_range, "http://syriaca.org/cbss/SYM5C6P5", map:size($mapBibls), "p")
    
    let $bibls := map:merge(($mapBibls, $indexBibls))
    
    
    let $placeNames := $rec/*:Syriaca_Headword/*:label/text() => distinct-values()
    let $placeNames := 
      for $name in $placeNames
      let $ranges := $sources?cited_ranges_by_name?$name
      
      let $maps := 
        for $k in map:keys($mapBibls)
        let $val := map:get($mapBibls, $k)
        where $val/*:citedRange/text() = $ranges?maps_cited_range
        return $k
      let $index :=
        for $k in map:keys($indexBibls)
        let $val := map:get($indexBibls, $k)
        where $val/*:citedRange/text() = $ranges?index_cited_range
        return $k
      return {
        "name": $name,
        "sources": ($maps, $index)
      }
    
    let $otherUris :=
        for $other in $rec/*:URIs_from_RevisedPlaces//text() | $rec/*:URIs_from_working-data//text()
        where normalize-space($other) != ""
        where normalize-space($other) != $uri (:skip the Syriaca URI so it's not duplicated:)
        return normalize-space($other)
    let $otherUris := distinct-values($otherUris)

    (:
    TBD: a side function that parses map appearances and index appearances, as well as 'requested by' info for the chapter bibls
    :)

    (: TBD: It looks like related places not used for existing Syriac World data records :)

    (: TBD: do we bring in existence dates? :)

    let $gps := process:parse-syriac-world-gps($rec/*:KML_LongLat_DD/*:label/text()) => distinct-values()
    (: Add source info; assuming all maps are included for each gps since they are not correlated in our dataset :)
    let $gps := 
      for $c in $gps
      return {
        "value": $c,
        "sources": map:keys($mapBibls)
      }

    return map:entry($uri, {
        "uri": $uri,
        "place_names": $placeNames,
        "other_uris": $otherUris,
        "gps": $gps,
        "bibls": $bibls
    })
    
};


declare function process:parse-syriac-world-gps($gps as xs:string*)
as xs:string* {
    for $coord in $gps
    where normalize-space($coord) != ""
    let $lat := tokenize($coord, ",")[2]
    let $long := tokenize($coord, ",")[1]
    return $lat||" "||$long
};

declare function process:create-other-data($other_data as map(*))
(: as map(*):) {
    for $k in map:keys($other_data)
    let $path := $other_data?$k?path
    let $extension := substring-after($path, ".")
    let $data := 
        switch($extension)
        case "csv" return csv:doc($path, map {"header": $other_data?$k?header, "separator": $other_data?$k?separator})
        case "xml" return doc($path)
        default return ()
    return map {
        $k: $data
    }
};

declare function process:collate-syriac-world-bib-info($uri as xs:string, $bibData as item())
as item()* {
    let $matchRows := $bibData/*:csv/*:record[*:Syriaca_URI[./text() = $uri]]

    let $citedRangeByName :=
        for $row in $matchRows
        let $name := $row/*:Syriaca_Headword/text() => normalize-space()
        return map {
            $name: {
                "maps_cited_range": $row/*:Maps_CitedRange/text(),
                "index_cited_range": $row/*:Index_CitedRange/text()
            }
        }
    
    let $distinctMapsCitedRanges := $matchRows/*:Maps_CitedRange/text() => distinct-values()
    let $distinctIndexCitedRanges := $matchRows/*:Index_CitedRange/text() => distinct-values()
    return map {
        "cited_ranges_by_name": $citedRangeByName,
        "distinct_maps_range": $distinctMapsCitedRanges,
        "distinct_index_range": $distinctIndexCitedRanges
    }
};

declare function process:create-bibl-map($citedRanges as xs:string*, $biblUri as xs:string, $offset as xs:integer := 0, $unit as xs:string := "p")
as item()* {
  map:merge(
  for $range at $i in $citedRanges
  let $bibl :=
    element {QName("http://www.tei-c.org/ns/1.0", "bibl")}{
      element {QName("http://www.tei-c.org/ns/1.0", "ptr")} {
        attribute {"target"} {$biblUri}
      },
      element {QName("http://www.tei-c.org/ns/1.0", "citedRange")} {
        attribute {"unit"} {$unit},
        $range
      }
    }
  return map {
    $i+$offset: $bibl
  }
)
};