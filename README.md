Python FHIR Parser
==================

A Python FHIR specification parser for model class generation.
The `generate.py` script downloads the latest [FHIR specification][fhir], parses resources and their search parameters and puts them into Python dictionaries.
These dictionaries are then used by [Jinja][] templates to create classes in certain programming languages (currently only _Swift_).

This script does its job for the most part, but it doesn't yet handle all FHIR pecularities and there's no guarantee the output is correct or complete.

### Use ###

1. Copy the file `settings.py` from the respective subdirectory into the project's root directory, 
2. Adjust the paths, if necessary
3. Execute `./generate.py` to run the script.
    This will use Python _3_, issue `python generate.py` if you don't have Python 3 yet.
    Supply the `-f` flag to force a re-download of the spec.

> NOTE that the script currently overwrites existing files without asking and without regret.


[fhir]: http://www.hl7.org/implement/standards/fhir/
[jinja]: http://jinja.pocoo.org
