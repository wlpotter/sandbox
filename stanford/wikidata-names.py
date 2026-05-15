import requests
import json, csv
import time

USER_AGENT = "SyriacaTSG/0.3 (https://syriaca.org/; william.potter@vanderbilt.edu)"

WHG_DATA = "/home/arren/Downloads/whg_dataset_1742.lpf"

OUTPUT_PATH = "/home/arren/Documents/GitHub/sandbox/stanford/wikidata-names.csv"

CACHE_DIRECTORY = "/home/arren/Documents/GitHub/sandbox/wikidata-cache/"

LANGUAGES = ["zh-hans", "zh-hant", "zh"]

FIELDNAMES = ["syriaca_uri", "wikidata_id", *LANGUAGES, "error_code"]

# headers = {'user-agent': 'my-app/0.0.1'}
places = []
# Get data from the WHG download
with open(WHG_DATA) as fh:
    whg_records = json.load(fh)
    for place in whg_records["features"]:
        syriaca_uri = place["properties"]["src_id"]
        wikidata_id = ''
        for link in place["properties"]["links"]:
            if(link["type"] == "closeMatch" and link["identifier"].startswith("wd:")):
                wikidata_id = link["identifier"][3:] if  link["identifier"][3:] != "None" else ''
            if wikidata_id != '': break
        
        places.append(
            {
                "syriaca_uri": syriaca_uri,
                "wikidata_id": wikidata_id
            }
        )

# Get the Wikidata record and parse for the Chinese labels

headers = {'User-Agent': USER_AGENT}
for place in places:
    # skip any without a wikidata ID
    if place["wikidata_id"] == '':
        continue
    
    # Get the JSON from Wikidata
    url = f'https://www.wikidata.org/wiki/Special:EntityData/{place["wikidata_id"]}.json'
    print(url)

    response = requests.get(url, headers=headers)
    try:
        response.raise_for_status
    except:
        place["error_code"] = response.status_code
        continue
    
    data = response.json()
    try:
        entity_id = place["wikidata_id"]

        # Handle cases where the two IDs differ, this is usually a redirect
        wikidata_id = list(data["entities"].keys())[0]
        if(entity_id != wikidata_id):
            place["error_code"] = f'Warning: Wikidata ID from WHG, {entity_id}, does not match the returned ID in the JSON, {wikidata_id}. This is likely due to a deprecation and redirect and can be ignored.'
            entity_id = wikidata_id

        # TODO: test before running
        for lang in LANGUAGES:
            place[lang] = data["entities"][entity_id]["labels"].get(lang, {}).get("value", '')
            alias_objs = data["entities"][entity_id]["aliases"].get(lang, [])
            aliases = [alias.get("value") for alias in alias_objs if "value" in alias]
            place[lang] += "\n"+"\n".join(aliases)
            place[lang].strip()

    except:
        place["error_code"] = "JSON parsing error"
    time.sleep(1.5)

with open(OUTPUT_PATH, mode="w+") as outfile:
    writer = csv.DictWriter(outfile, fieldnames=FIELDNAMES)
    writer.writeheader()
    for place in places:
        writer.writerow(place)
