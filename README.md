FHIR Zeug - A FHIR Spec Compiler
================================

(forked from https://github.com/smart-on-fhir/fhir-parser)


Why a fork?
-----------
The original project seemed to abandoned and its structure was not quite pythonic. The work which 
has been done was great and we wanted to continue development here. We wanted to have a more
self-contained project, which already has the definitions for the languages on board.

Our main support goals are Python (3.8) with [pydantic](https://github.com/samuelcolvin/pydantic/)
and [FHIR R4](https://hl7.org/fhir/R4/).


This work is licensed under the [APACHE license][license].
FHIR® is the registered trademark of [HL7](http://hl7.org) and is used with the permission of HL7.


Usage
-----

The `fhir_zeug.cli` module is the central cli utility included. In an installed environment it can
be called with

```
# fhir-zeug --help
Usage: fhir-zeug [OPTIONS]

  Download and parse FHIR resource definitions.

Options:
  --force-download / --no-force-download
  --dry-run / --no-dry-run
  --force-cache / --no-force-cache
  --load-only / --no-load-only
  --install-completion [bash|zsh|fish|powershell|pwsh]
                                  Install completion for the specified shell.
  --show-completion [bash|zsh|fish|powershell|pwsh]
                                  Show completion for the specified shell, to
                                  copy it or customize the installation.

  --help                          Show this message and exit.
```

It will:
- Download the [FHIR specification][fhir]
- Parse it
- Generate source files for python pydantic




# Obsolete


downloads [FHIR specification][fhir] files, parses the profiles (using _fhirspec.py_) and represents them as `FHIRClass` instances with `FHIRClassProperty` properties (found in _fhirclass.py_).
Additionally, `FHIRUnitTest` (in _fhirunittest.py_) instances get created that can generate unit tests from provided FHIR examples.
These representations are then used by [Jinja][] templates to create classes in certain programming languages, mentioned below.

This script does its job for the most part, but it doesn't yet handle all FHIR peculiarities and there's no guarantee the output is correct or complete.
This repository **does not include the templates and base classes** needed for class generation, you must do this yourself in your project.
You will typically add this repo as a submodule to your framework project, create a directory that contains the necessary base classes and templates, create _settings_ and _mappings_ files and run the script.
Examples on what you would need to do for Python classes can be found in _Sample/settings.py_, _Sample/mappings.py_ and _Sample/templates*_.


Use
---

1. Add `fhir-parser` as a submodule/subdirectory to the project that will use it
2. Create the file `mappings.py` in your project, to be copied to fhir-parser root.
    First, import the default mappings using `from Default.mappings import *` (unless you will define all variables yourself anyway).
    Then adjust your `mappings.py` to your liking by overriding the mappings you wish to change.
3. Similarly, create the file `settings.py` in your project.
    First, import the default settings using `from Default.settings import *` and override any settings you want to change.
    Then, import the mappings you have just created with `from mappings import *`.
    The default settings import the default mappings, so you may need to overwrite more keys from _mappings_ than you'd first think.
    You most likely want to change the topmost settings found in the default file, which are determining where the templates can be found and generated classes will be copied to.
4. Install the generator's requirements by running `pip3` (or `pip`):
    ```bash
    pip3 install -r requirements.txt
    ```

5. Create a script that copies your `mappings.py` and `settings.py` file to the root of `fhir-parser`, _cd_s into `fhir-parser` and then runs `generate.py`.
    The _generate_ script by default wants to use Python _3_, issue `python generate.py` if you don't have Python 3 yet.
    * Supply the `-f` flag to force a re-download of the spec.
    * Supply the `--cache-only` (`-c`) flag to deny the re-download of the spec and only use cached resources (incompatible with `-f`).

> NOTE that the script currently overwrites existing files without asking and without regret.






Tech Details
============

This parser still applies some tricks, stemming from the evolving nature of FHIR's profile definitions.
Some tricks may have become obsolete and should be cleaned up.

### How are property names determined?

Every “property” of a class, meaning every `element` in a profile snapshot, is represented as a `FHIRStructureDefinitionElement` instance.
If an element itself defines a class, e.g. `Patient.animal`, calling the instance's `as_properties()` method returns a list of `FHIRClassProperty` instances – usually only one – that indicates a class was found in the profile.
The class of this property is derived from `element.type`, which is expected to only contain one entry, in this matter:

- If _type_ is `BackboneElement`, a class name is constructed from the parent element (in this case _Patient_) and the property name (in this case _animal_), camel-cased (in this case _PatientAnimal_).
- If _type_ is `*`, a class for all classes found in settings` `star_expand_types` is created
- Otherwise, the type is taken as-is (e.g. _CodeableConcept_) and mapped according to mappings' `classmap`, which is expected to be a valid FHIR class.

> TODO: should `http://hl7.org/fhir/StructureDefinition/structuredefinition-explicit-type-name` be respected?


[license]: ./LICENSE.txt
[hl7]: http://hl7.org/
[fhir]: http://www.hl7.org/implement/standards/fhir/
[jinja]: http://jinja.pocoo.org/
