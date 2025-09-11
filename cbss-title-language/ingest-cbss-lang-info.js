/*
author: William L. Potter
version: 1.0
This JS can be run using the Zotero desktop client to update the title language of the 

It requires a JSON file mapping Zotero ItemKeys to the title language, publication language, and language note information.

The title language will be stored as the Item's language field to ensure proper capitalization rules are followed. Other language information will be stored in the Extra field under the "PubLang" and "LangNote" keys/value pairs.

To run the script, ensure that the following fields are correct:
LANGUAGE_FILE_LOCATION (must be a JSON file, stored on a remote server -- GitHub gists are recommended)

COLUMN_LABELS (the values of each item should reflect the key labels in the file at the LANGUAGE_FILE_LOCATION)

1. Open the Zotero desktop client
2. Select the Group Library you would like to run the script on, so that it is your "Active Pane"
3. From the menu, open the Tools > Developer > Run JavaScript modal
4. Select the "Run as async function" option
5. Paste this full script into the Code window
6. Click "Run" (ctrl/cmd + R)
7. Returns a report of which rows were successful, and any errors that occured, providing the item key for the errors
*/

const LANGUAGE_FILE_LOCATION = "https://gist.githubusercontent.com/wlpotter/d961288461fd1d22846bbe233303f941/raw/e21e79859f20996eddd81b265b4ba74df7d3e6b0/test-cbss-title-lang.json"; // Must be an http URL to a JSON document containing the ItemKeys mapped to the language information

const COLUMN_LABELS = {
    "ItemKey": "ItemKey",
    "TitleLang": "TitleLanguage",
    "PubLang": "PubLang",
    "LangNote": "LangNote"
}

// Download the JSON with language info from the remote server
let lang_data = await fetch(LANGUAGE_FILE_LOCATION)
    .then(response => response.json());


let results_log = []
//loop through each item 'row' in the language file and update the corresponding Zotero item's language info
for (let item of lang_data) {
    let search_result = await getZoteroItemByKey(item[COLUMN_LABELS.ItemKey])
    if(typeof search_result == "object") {
        await updateZoteroItemLanguageInfo(search_result, item, COLUMN_LABELS)
        results_log.push("Successfully updated item " + search_result.key)
    } else {
        // If the search returns something other than an object, e.g. a string with an error report, log it
        results_log.push(search_result)
    };
};

return results_log

// it's annoying to redo the search each time, but not sure how else to get items by ID...
async function getZoteroItemByKey(itemKey) {
    var s = new Zotero.Search();
    s.libraryID = ZoteroPane.getSelectedLibraryID();
    s.addCondition('key', 'is', itemKey);
    var ids = await s.search();
    if (!ids.length) {
        return "No items found: " + itemKey;
    }
    for (let id of ids) {
        let item = await Zotero.Items.getAsync(id);
        //for some reason, no matches still returns a default item? So this block checks whether the returned item's key actually matches or not
        if(item.getField('key') == itemKey) {
            return item;
        }
        else {
            return "Item key mismatch: " + "Search Key: " + itemKey + " Does not equal return key: " + item.getField('key');
        }
    };
};

async function updateZoteroItemLanguageInfo(item, langInfo, columnLabels) {

    //Update the Item's language field if there is a declared Title Language
    if(langInfo[columnLabels.TitleLang]) {
        item.setField('language', langInfo[columnLabels.TitleLang])
    };
    
    //get the Zotero Item's extra field
    var extra = item.getField('extra');
    
    //get the pub lang and language note fields from the 'csv' data
    var pubLang = langInfo[columnLabels.PubLang]
    var langNote = langInfo[columnLabels.LangNote]
    
    //create the key/value pairs, or set to an empty string
    if(pubLang) {
        pubLang = "PubLang: " + pubLang
    } else {
        pubLang = ""
    };
    if(langNote) {
        langNote = "LangNote: " + langNote
    } else {
        langNote = ""
    };
    
    //create a formatted append string for the values
    var append_extra = [pubLang, langNote].join("\n").trim()
    
    //prepare the extra field for the new key/value pairs
    if(extra.length > 0 && append_extra.length > 0) {
        extra += "\n"
    };
    extra += append_extra
    
    item.setField('extra', extra)

    await item.saveTx();
};