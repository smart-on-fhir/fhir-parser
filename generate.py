#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  Download and parse FHIR resource definitions
#  Supply "-f" to force a redownload of the spec
#  Supply "-c" to force using the cached spec (incompatible with "-f")
#  Supply "-d" to load and parse but not write resources
#  Supply "-l" to only download the spec

import sys

import settings
import fhirloader
import fhirspec


if '__main__' == __name__:
    force_download = len(sys.argv) > 1 and '-f' in sys.argv
    dry = len(sys.argv) > 1 and ('-d' in sys.argv or '--dry-run' in sys.argv)
    load_only = len(sys.argv) > 1 and ('-l' in sys.argv or '--load-only' in sys.argv)
    force_cache = len(sys.argv) > 1 and ('-c' in sys.argv or '--cache-only' in sys.argv)

    # assure we have all files
    loader = fhirloader.FHIRLoader(settings)
    spec_source = loader.load(force_download=force_download, force_cache=force_cache)

    # parse
    if not load_only:
        spec = fhirspec.FHIRSpec(spec_source, settings)
        if not dry:
            spec.write()
