import csv


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

data_source = "lrda_data_source.csv"
with open(data_source, newline='', encoding='utf-8') as f:
    parser = csv.reader(f, delimiter="\t")
    for row in parser:
        print(transform_date_name_string(row[1]))
