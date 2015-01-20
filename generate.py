#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  Download and parse FHIR resource definitions
#  Supply "-f" to force a redownload of the spec

import io
import sys
import os.path
import shutil
import re
import datetime
import logging

import fhirspec

_cache = 'downloads'


def download(url, path):
    """ Download the given URL to the given path.
    """
    import requests     # import here as we can bypass its use with a manual download
    
    ret = requests.get(url)
    assert(ret.ok)
    with io.open(path, 'wb') as handle:
        for chunk in ret.iter_content():
            handle.write(chunk)


def expand(path, target):
    """ Expand the ZIP file at the given path to the given target directory.
    """
    assert(os.path.exists(path))
    import zipfile      # import here as we can bypass its use with a manual unzip
    
    with zipfile.ZipFile(path) as z:
        z.extractall(target)


if '__main__' == __name__:
    import settings as _settings
    from logger import logger
    
    # start from scratch?
    if len(sys.argv) > 1 and '-f' == sys.argv[1]:
        if os.path.isdir(_cache):
            shutil.rmtree(_cache)
    
    # download spec if needed and extract
    spec_url = _settings.specification_url
    spec_path = os.path.join(_cache, spec_url.split('/')[-1])
    spec_source = os.path.join(_cache, 'site')
    
    if not os.path.exists(spec_path):
        if not os.path.isdir(_cache):
            os.mkdir(_cache)
        logger.info('Downloading FHIR spec')
        download(spec_url, spec_path)
        logger.info('Extracting to {}'.format(_cache))
        expand(spec_path, _cache)
    else:
        logger.info('Using cached FHIR spec, supply "-f" to re-download')
    
    # parse
    spec = fhirspec.FHIRSpec(spec_source, _settings)
    spec.write()

