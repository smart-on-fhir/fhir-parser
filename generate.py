#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  Download and parse FHIR resource definitions
#  Supply "-f" to force a redownload of the spec

import sys

import settings
import fhirloader
import fhirspec

_cache = 'downloads'


if '__main__' == __name__:
    force = len(sys.argv) > 1 and '-f' == sys.argv[1]
    
    # assure we have all files
    loader = fhirloader.FHIRLoader(settings, _cache)
    spec_source = loader.load(force)
    
    # parse
    spec = fhirspec.FHIRSpec(spec_source, settings)
    spec.write()
