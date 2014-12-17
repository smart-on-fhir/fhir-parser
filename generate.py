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

from jinja2 import Environment, PackageLoader
from jinja2.filters import environmentfilter

import fhirspec

_cache = 'downloads'


# deprecated, going away when FHIRSpec is done
jinjaenv = Environment(loader=PackageLoader('generate', '.'))


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


# deprecated, going away when FHIRSpec is done
def parse_DEPRECATED(path):
    """ Parse all JSON profile definitions found in the given expanded
    directory, create classes for all found profiles, collect all search params
    and generate the search param extension.
    """
    assert(os.path.exists(path))
    
    # get FHIR version
    version = None
    with io.open(os.path.join(path, 'version.info'), 'r', encoding='utf-8') as handle:
        text = handle.read()
        for line in text.split("\n"):
            if '=' in line:
                (n, v) = line.split('=', 2)
                if 'FhirVersion' == n:
                    version = v
    
    assert(version is not None)
    print("->  This is FHIR version {}".format(version))
    now = datetime.date.today()
    info = {
        'version': version.strip() if version else 'X',
        'date': now.isoformat(),
        'year': now.year
    }
    
    # parse profiles
    ## IMPLEMENTED in FHIRSpec()
    
    # process element factory
    ## IMPLEMENTED in FHIRSpec()
    
    # process search parameters
    process_search(search_params, in_profiles, info)
    
    # detect and process unit tests
    ## IMPLEMENTED in FHIRSpec()/FHIRUnitTest()


# deprecated, going away when FHIRSpec is done
def process_search(params, in_profiles, info):
    """ Processes and renders the FHIR search params extension.
    """
    if not write_searchparams:
        print("oo>  Skipping search parameters")
        return
    
    extensions = []
    dupes = set()
    for param in sorted(params):
        (name, orig, typ) = param.split('|')
        finalname = reservedmap.get(name, name)
        for d in extensions:
            if finalname == d['name']:
                dupes.add(finalname)
        
        extensions.append({'name': finalname, 'original': orig, 'type': typ})
    
    data = {
        'info': info,
        'extensions': extensions,
        'in_profiles': in_profiles,
        'dupes': dupes,
    }
    render(data, tpl_searchparams_source, tpl_searchparams_target)


# deprecated, going away when FHIRSpec is done
def render(data, template, filepath):
    """ Render the given class data using the given Jinja2 template, writing
    the output into the file at `filepath`.
    """
    assert(os.path.exists(template))
    template = jinjaenv.get_template(template)
    
    if not filepath:
        raise Exception("No target filepath provided")
    dirpath = os.path.dirname(filepath)
    if not os.path.isdir(dirpath):
        os.makedirs(dirpath)
    
    with io.open(filepath, 'w', encoding='utf-8') as handle:
        logging.info('Writing {}'.format(filepath))
        rendered = template.render(data)
        handle.write(rendered)
        # handle.write(rendered.encode('utf-8'))


# deprecated, going away when FHIRSpec is done

# There is a bug in Jinja's wordwrap (inherited from `textwrap`) in that it
# ignores existing linebreaks when applying the wrap:
# https://github.com/mitsuhiko/jinja2/issues/175
# Here's the workaround:
@environmentfilter
def do_wordwrap(environment, s, width=79, break_long_words=True, wrapstring=None):
    """
    Return a copy of the string passed to the filter wrapped after
    ``79`` characters.  You can override this default using the first
    parameter.  If you set the second parameter to `false` Jinja will not
    split words apart if they are longer than `width`.
    """
    import textwrap
    if not wrapstring:
        wrapstring = environment.newline_sequence
    
    accumulator = []
    # Workaround: pre-split the string
    for component in re.split(r"\r?\n", s):
        # textwrap will eat empty strings for breakfirst. Therefore we route them around it.
        if len(component) is 0:
            accumulator.append(component)
            continue
        accumulator.extend(
            textwrap.wrap(component, width=width, expand_tabs=False,
                replace_whitespace=False,
                break_long_words=break_long_words)
        )
    return wrapstring.join(accumulator)

jinjaenv.filters['wordwrap'] = do_wordwrap


if '__main__' == __name__:
    import settings as _settings
    logging.basicConfig(level=logging.DEBUG)
    
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
        logging.info('Downloading FHIR spec')
        download(spec_url, spec_path)
        logging.info('Extracting to {}'.format(_cache))
        expand(spec_path, _cache)
    else:
        logging.info('Using cached FHIR spec, supply "-f" to re-download')
    
    # parse
    spec = fhirspec.FHIRSpec(spec_source, _settings)
    spec.write()

