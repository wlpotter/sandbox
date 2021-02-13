import csv
# NOTE: Requires a data source to be identified. To maintain confidentiality,
# I have not included the data inputs and outputs in the public git repo

def transform_date_name_string(string):
    """ (str) -> [str, str]

    Takes as input a string of the form "YYYYMMDD_NameOfString".
    Returns a list of two strings,
    First of the form "YYY-MM-DD"
    Second of the form "Name Of String"

    >>> transform_date_name_string("20190710_WorldsFairPavilion")
    ["2019-07-10", "Worlds Fair Pavilion"]
    >>> transform_date_name_string("20190712_BackToBasicsChristianBookstore")
    ["2019-07-12", "Back To Basics Christian Bookstore"]
    >>> transform_date_name_string("20190712_HinduTempleStLouis")
    ["2019-07-12", "Hindu Temple St Louis"]
    """
    date = string[0:4]+"-"+string[4:6]+"-"+string[6:8]
    name = add_spaces(string[9:])
    return [date, name]


def add_spaces(no_space_string):
    """(str) -> str

    Takes as input a string of the form "NameOfString"
    Returns a string with whitespace inserted before capital letters

    >>> add_spaces("HinduTempleStLouis")
    "Hindu Temple St Louis"
    """
    space_string = ""
    i = 0
    for ch in no_space_string:
        if (ch.isupper() and i != 0):
            space_string += (" "+ch)
        else:
            space_string += ch
        i += 1
    return space_string


def create_short_description(category, folder_name):
    transformed_date_name_string = transform_date_name_string(folder_name)
    name = transformed_date_name_string[1]
    date = transformed_date_name_string[0]
    location_preamble = ""
    if (category == "Location"):
        location_preamble = name + ", "
    return "Name: " + name + "\n" + "Date: " + date + "\nLocation: "\
        + location_preamble + "Saint Louis, MO, USA\nDescription: \nExtra: "


data_source = "lrda_data_source.csv"
output_file = open("lrda_data_output.csv", "w+")
with open(data_source, newline='', encoding='utf-8') as f:
    parser = csv.reader(f, delimiter="\t")
    writer = csv.writer(output_file, delimiter=' ', quotechar='"', quoting=csv.QUOTE_ALL)
    i = 0
    for row in parser:
        short_description = create_short_description(row[0], row[1])
        if i != 0:
            row[5] = short_description
        writer.writerow(row)
        # write the row
        i += 1
        print(short_description + "\n---\n")
