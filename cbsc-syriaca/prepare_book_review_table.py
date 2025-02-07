import json, csv

CBSS_ZOTERO_URI_BASE = "http://zotero.org/groups/4861694/items/"
CBSS_URI_BASE = "http://syriaca.org/cbss/"

CBSS_JSON_DATA = "/home/arren/cbss_data-dump_local_2025-02-05.json"
CBSS_BOOK_REVIEWS_COLLECTION_KEY = "VNRH9D6Q"

OUTPUT_FILE = "/home/arren/Documents/GitHub/sandbox/cbsc-syriaca/out/book-review-checking.csv"
CSV_HEADERS = ["Book Review URI", "Book Review CBSS URI", "Title", "Creator", "Year", "Reviewed Item URI", "Reviewed Item CBSS URI", "Is Reviewed Item Deprecated"]

book_reviews = []

with open(CBSS_JSON_DATA, "r") as f:
    data = json.load(f)

    book_review_collection = data["collections"][CBSS_BOOK_REVIEWS_COLLECTION_KEY]
    book_review_item_ids = book_review_collection["items"]

    # gather the subset of items that are in the book-reviews collection
    for item in data["items"]:
        if item["itemID"] in book_review_item_ids:
            item["reviewed_uri"] = []
            item["reviewed_zotero_uri"] = []
            item["reviewed_rec_is_deprecated"] = []
            if "extra" in item:
                extra = item["extra"].splitlines()
                for e in extra:
                    if e.startswith("ReviewOf"):
                        # catches typos where the extra key doesn't have a space
                        try:
                            reviewed_uri = e.split("ReviewOf: ")[1]
                        except:
                            reviewed_uri = e.split("ReviewOf:")[1]
                        reviewed_zot_uri = reviewed_uri.replace(CBSS_URI_BASE, CBSS_ZOTERO_URI_BASE)
                        item["reviewed_uri"].append(reviewed_uri)
                        item["reviewed_zotero_uri"].append(reviewed_zot_uri)
                        # check if the reviewed record is deprecated
                        for reviewed_item in data["items"]:
                            if reviewed_item["uri"] == reviewed_zot_uri:
                                is_deprecated = False
                                for tag in reviewed_item["tags"]:
                                    is_deprecated = tag["tag"] == "_deprecated"
                                    if is_deprecated:
                                        break
                                item["reviewed_rec_is_deprecated"].append(str(is_deprecated))
                                break            
            book_reviews.append(item)


with open(OUTPUT_FILE, "w+", newline='') as csvfile:
    writer = csv.writer(csvfile, delimiter=",")
    writer.writerow(CSV_HEADERS)
    for review in book_reviews:
        # creator names: get all creators, use either lastName or name if no lastName
        creator_names = []
        for creator in review["creators"]:
            creator_names.append(creator.get("lastName") or creator.get("name") or "")
        writer.writerow([
                review["uri"],
                review["uri"].replace(CBSS_ZOTERO_URI_BASE, CBSS_URI_BASE),
                review["title"],
                ', '.join(creator_names),
                review.get("date") or '',
                "#".join(review["reviewed_zotero_uri"]),
                "#".join(review["reviewed_uri"]),
                "#".join(review["reviewed_rec_is_deprecated"])
            ])