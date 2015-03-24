Python FHIR Parser
==================

A Python FHIR specification parser for model class generation.
The _generate.py_ script downloads [FHIR specification][fhir] files, parses the profiles and represents them as `FHIRClass` instances with `FHIRClassProperty` properties (found in _fhirclass.py_).
Additionally, `FHIRUnitTest` (in _fhirunittest.py_) instances get created that can generate unit tests from provided FHIR examples.
These representations are then used by [Jinja][] templates to create classes in certain programming languages, mentioned below.

This script does its job for the most part, but it doesn't yet handle all FHIR pecularities and there's no guarantee the output is correct or complete.
Unless you have a desire to understand how parsing works, you should be able to play with _Lang/settings.py_, _Lang/mappings.py_ and _Lang/templates*_ to achieve what you need.

The `master` branch is currently on _DSTU 1_.  
The `develop` branch is currently on _DSTU 2_ and WiP.

### Use ###

1. Copy the file `settings.py` from the respective subdirectory into the project's root directory, 
2. Adjust settings, if necessary
3. Execute `./generate.py` to run the script.
    This will use Python _3_, issue `python generate.py` if you don't have Python 3 yet.
    Supply the `-f` flag to force a re-download of the spec.

> NOTE that the script currently overwrites existing files without asking and without regret.


Languages
=========

This repo currently supports class generation in the following languages:

Swift
-----

[Swift][], Apple's new programming language for OS X and iOS.
Since the language is still under active development, the repo will be updated when a language change occurrs.
The current supported "version" corresponds to what's accepted by Xcode 6.2.
The [Swift-FHIR][] repo contains the latest generated Swift classes.

Python
------

Classes for Python are targeted towards Python 3 but will support the later 2.x versions – at least they should.
All resource classes will inherit from the `FHIRResource` base class, which is a subclass of `FHIRElement`.
Dates are expressed as `FHIRDate` instances which can parse valid ISO dates.

### Python TODO: ###

```text
[x] Generate Python classes
[x] Deserialize from JSON
[x] Implement reference resolver (for contained resources)
[ ] Implement reference resolver (for remote resources)
[ ] Serialize to JSON
[ ] Generate search parameter builder
[ ] Generate unit tests from JSON example files
```

### Requirements ###

```text
isodate
```


[fhir]: http://www.hl7.org/implement/standards/fhir/
[jinja]: http://jinja.pocoo.org
[swift]: https://developer.apple.com/swift/
[swift-fhir]: https://github.com/smart-on-fhir/Swift-FHIR
