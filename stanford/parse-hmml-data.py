import json, csv, os

"""
Takes a @proc dictionary representing a manuscript (or part)
And a @part dictionary representing an object in the HMML data parts array
Updates the @proc dictionary in-place with data from the part
Returns None as no data is needed
"""
def add_info_from_part(proc: dict, part: dict):
    
    # Overwrite ms-level with part-level support info if present
    # everything that has a supportImported has a support in the parts
    proc["support"] = part.get("support", proc["support"])

    # Locus
    proc["locus"] = part.get("partLocation")
    # Dimensions; note that https://www.vhmml.org/dataPortal/schema indicates these are cm 
    proc["height_cm"] = part.get("supportDimensionsHeight")
    proc["width_cm"] = part.get("supportDimensionsWidth")

    # Layout; note that will require parsing
    proc["layout"] = part.get("layout")
    # Dates
    proc["date_after"] = part.get("beginDate")
    proc["date_before"] = part.get("endDate")

ALPHA = list("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
fpath = "/home/arren/Downloads/vHMML_fulldata_rr_20260204_3515.json"
outpath = os.getcwd() + "/out/"
outfilename = "hmml-data-post-1600" #used for both CSV and JSON dumps


processed = []

with open(fpath) as fh:
    data = json.load(fh)
    for rec in data:
        proc_rec = {}
        proc_rec["uri"] = rec["PURL"]
        proc_rec["shelfmark"] = rec.get("shelfMark", rec.get("hmmlProjectNumber"))
        proc_rec["hmml_project_number"] = rec.get("hmmlProjectNumber")
        proc_rec["country"] = rec.get("country").get("name")
        proc_rec["city"] = rec.get("city").get("name")
        proc_rec["holding_institution"] = rec.get("holdingInstitution").get("name")
        proc_rec["repository"] = rec.get("repository").get("name")
        proc_rec["collection"] = rec.get("collection")

        # Form TODO
        """
        - can check for a Fragments feature term (85 have this term)
        - maybe check if binding is set?
        - there's no specific form of codex vs leaves (I suppose could use the folio extents? What is a good cut-off?)
        """
        # Support
        proc_rec["support"] = rec.get("support")

        # Get a list of the genres (delimited by " | ")
        proc_rec["hmml_genres"] = " | ".join([g["name"] for g in rec.get("genres")])

        # For single part mss, use this as the whole rec
        if len(rec.get("parts")) == 1:
            add_info_from_part(proc_rec, rec["parts"][0])
            processed.append(proc_rec)
        # Otherwise, add a row for each part
        else:
            for i, part in enumerate(rec.get("parts")):
                # make a copy of all the collection, etc. info
                proc_part = proc_rec.copy()
                
                # Add an alphabetic value to distinguish parts
                print(proc_part["uri"])
                proc_part["shelfmark"] = proc_part["shelfmark"] + " " + ALPHA[i]

                # Add the part-specific info for this record
                add_info_from_part(proc_part, part)

                processed.append(proc_part)

                # TODO: genres will need to be cleaned since they aren't at each part level...
        
os.makedirs(outpath, exist_ok=True)
with open (outpath+outfilename+".csv", mode="w+") as fh:
    fieldnames = list(processed[0].keys())
    writer = csv.DictWriter(fh, fieldnames=fieldnames)
    writer.writeheader()
    for p in processed:
        writer.writerow(p)

with open (outpath+outfilename+".json", mode="w+") as fh:
    json.dump(processed, fh, indent=2, ensure_ascii=False)