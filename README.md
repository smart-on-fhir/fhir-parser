Python FHIR Parser
==================

A Python FHIR specification parser for model class generation.
If you've come here because you want _Swift_ or _Python_ classes for FHIR data models, look at our client libraries instead:

- [Swift-FHIR](https://github.com/smart-on-fhir/Swift-FHIR) and [Swift-SMART](https://github.com/smart-on-fhir/Swift-SMART)
- Python [client-py](https://github.com/smart-on-fhir/client-py)

### Tech ###

The _generate.py_ script downloads [FHIR specification][fhir] files, parses the profiles and represents them as `FHIRClass` instances with `FHIRClassProperty` properties (found in _fhirclass.py_).
Additionally, `FHIRUnitTest` (in _fhirunittest.py_) instances get created that can generate unit tests from provided FHIR examples.
These representations are then used by [Jinja][] templates to create classes in certain programming languages, mentioned below.

This script does its job for the most part, but it doesn't yet handle all FHIR pecularities and there's no guarantee the output is correct or complete.
Unless you have a desire to understand how parsing works, you should be able to play with _Lang/settings.py_, _Lang/mappings.py_ and _Lang/templates*_ to achieve what you need.

The `master` branch is currently on _DSTU 2, May 2015 ballot_.  
The `develop` branch is currently on _DSTU 2_ and WiP.

See [tags](https://github.com/smart-on-fhir/fhir-parser/releases) for other specific FHIR versions.

### Use ###

1. Copy the file `settings.py` from the language's subdirectory into the project's root directory, then
2. Adjust settings, especially those determining where the generated classes will be copied to, found at the top of `settings.py`.
3. Install requirements by running `pip3` (or `pip`):
    ```bash
    pip3 install -r requirements.txt
    ```

4. Run the script:
    ```bash
    ./generate.py
    ```
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

The Swift classes depend on two protocols to be implemented, defined in `Swift/FHIRServer.swift`.
Implementations are provided by the [Swift-FHIR][] library.

Python
------

Classes for Python are targeted towards Python 3 but will support the later 2.x versions – at least they should.
All resource classes will inherit from the `FHIRResource` base class, which is a subclass of `FHIRElement`.
Dates are expressed as `FHIRDate` instances which can parse valid ISO dates.

The generated classes will use relative imports in the form `from . import medication`.
This avoids namespaces clashes but requires that you use them from within a package.
See the [SMART Python Client][client-py] for a setup that works (all model classes are in a `models` subdirectory).


### Python TODO: ###

```text
[x] Generate Python classes
[x] Deserialize from JSON
[x] Implement reference resolver (for contained resources)
[ ] Implement reference resolver (for remote resources)
[ ] Implement working with references in code
[x] Serialize to JSON
[x] Generate search parameter builder
[x] Generate unit tests from JSON example files
```

### Requirements ###

The generated Python classes require the following packages to be installed:

```text
isodate
```


[fhir]: http://www.hl7.org/implement/standards/fhir/
[jinja]: http://jinja.pocoo.org
[swift]: https://developer.apple.com/swift/
[swift-fhir]: https://github.com/smart-on-fhir/Swift-FHIR
[client-py]: https://github.com/smart-on-fhir/client-py
