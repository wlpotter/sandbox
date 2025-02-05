import json, csv

"""
TBD:
- get the updated data dump from CBSS Zotero
- update the output file path
- figure out if you want to do anything about the records that deprecate CBSS records...(show up in the column with the Zotero group 48... so easy to find)
"""



CBSS_ZOTERO_URI_BASE = "http://zotero.org/groups/4861694/items/"
CBSS_URI_BASE = "http://syriaca.org/cbss/"

CBSS_JSON_DATA = "/home/arren/cbss_data-dump_local_2025-02-05.json"

OUTPUT_FILE = "/home/arren/Documents/GitHub/sandbox/cbsc-syriaca/out/deprecated-bibl-uri-crosswalk.csv"
CSV_HEADERS = ["Deprecated Syriaca URI", "CBSS URI"]

deprecated = []

with open(CBSS_JSON_DATA, "r") as f:
    data = json.load(f)
    for item in data["items"]:
        uri = item["uri"].replace(CBSS_ZOTERO_URI_BASE, CBSS_URI_BASE)
        # if the item's extra field is not empty
        if "extra" in item:
            extra = item["extra"].splitlines()
            # go through the extra key:value pairs, looking only at the 'deprecated' ones
            for e in extra:
                if(e.startswith("deprecated: ")):
                    deprecated_uri = e.split("deprecated: ")[1]
                    deprecated.append(
                        {
                            "deprecated_uri": deprecated_uri,
                            "cbss_uri": uri
                        }
                    )
with open(OUTPUT_FILE, "w+", newline='') as csvfile:
    writer = csv.writer(csvfile, delimiter=",")
    writer.writerow(CSV_HEADERS)
    for uri in deprecated:
        writer.writerow([uri["deprecated_uri"], uri["cbss_uri"]])