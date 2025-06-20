from BaseXClient import BaseXClient
import json, argparse

"""
INSTRUCTIONS:
- basex must be installed
- use the terminal to run `basexhttp -c PASSWORD` to set the admin password to 'admin' and start a basex server
- must install the python BaseXClient library (use pip inside your virtual environment)
- run via commandline. for now use the -c flag and specify a config file; use the sample config.json
- still in progress, but will add a section to the config for specifying the basex options like writeback control and serialization indents, etc.
"""
# Set up and parse command line arguments
parser = argparse.ArgumentParser(
                    prog='Syriaca Ingest',
                    description='Ingests data to existing Syriaca.org records')

parser.add_argument("-i", "--interactive", help="Execute script interactively", action="store_true")
parser.add_argument("-c", "--config", help="Specify the path to a configuration file")
# parser.add_argument("data_directory", help="Specify a path to the data directory")
"""
TBD:
- write the function for configuring data interactively
"""
args = parser.parse_args()

config = {}

if args.interactive:
    config = {}
else:
    with open(args.config, 'r') as f:
        config = json.load(f)
# print(config)


"""
Set up BaseX Session and Query
"""
# TBD: rewrite to use the config file
session = BaseXClient.Session('localhost', 1984, 'admin', 'admin')

"""
TBD: Set options for the query using
session.execute(command)
- set indentation, omit-xml-declaration, etc.
- set writeback
"""

try:
    with open(config["working_dir"]+'main.xq', 'r') as f:
        # read in the main file as a BaseX Query object
        query = session.query(f.read())
        
        # bind external variables for the query
        for k, v in config["ext_var"].items():
            query.bind(v["name"], v["value"])

        options = json.dumps(config["options"])
        query.bind("$options_string", options)
        # Execute the Query; TBD: prints any errors that are found?
        result = query.execute()
        print(result)

        # close query object
        query.close()
# TBD: add error handling/reporting
finally:
    # close session
    if session:
        session.close()