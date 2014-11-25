#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  Download and parse FHIR resource definitions
#  Supply "-f" to force a redownload of the spec

import io
import sys
import os.path
import shutil
import glob
import re
import json
import datetime
import logging

from jinja2 import Environment, PackageLoader
from jinja2.filters import environmentfilter

from settings import *
import fhirspec


cache = 'downloads'
loglevel = 0

skip_properties = [
    'extension',
    'modifierExtension',
    'language',
    'contained',
]

jinjaenv = Environment(loader=PackageLoader('generate', '.'))


def log0(*logstring):
    if loglevel >= 0:
        print(' '.join(str(s) for s in logstring))

def log1(*logstring):
    if loglevel > 0:
        print(' '.join(str(s) for s in logstring))


def download(url, path):
    """ Download the given URL to the given path.
    """
    import requests     # import here as we can bypass its use with a manual download
    
    log0('->  Downloading {}'.format(url))
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
    
    log0('->  Extracting to {}'.format(target))
    with zipfile.ZipFile(path) as z:
        z.extractall(target)


def parse(path):
    """ Instantiate FHIRSpec from the given directory. Then parse all profiles
    and create class objects for profiles to write classes and unit tests.
    Collect all search params to be able to create a nice search interface.
    """
    spec = fhirspec.FHIRSpec(path)
    print("version:", spec.info.version)
    spec.write()



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
    log0("->  This is FHIR version {}".format(version))
    now = datetime.date.today()
    info = {
        'version': version.strip() if version else 'X',
        'date': now.isoformat(),
        'year': now.year
    }
    
    # parse profiles
    ## IMPLEMENTED in FHIRSpec()
    
    # process element factory
    process_factories(factories, info)
    
    # process search parameters
    process_search(search_params, in_profiles, info)
    
    # detect and process unit tests
    process_unittests(path, all_classes, info)


def process_factories(factories, info):
    """ Renders a template which creates an extension to FHIRElement that has
    a factory method with all FHIR resource types.
    """
    if not write_factory:
        log1("oo>  Skipping factory")
        return
    
    data = {
        'info': info,
        'classes': factories,
    }
    render(data, tpl_factory_source, tpl_factory_target)


def process_search(params, in_profiles, info):
    """ Processes and renders the FHIR search params extension.
    """
    if not write_searchparams:
        log1("oo>  Skipping search parameters")
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


def process_unittests(path, classes, info):
    """ Finds all example JSON files and uses them for unit test generation.
    Test files use the template `tpl_unittest_source` and dump it according to
    `tpl_unittest_target_ptrn`.
    """
    all_tests = {}
    for utest in glob.glob(os.path.join(path, '*-example*.json')):
        log0('-->  Parsing unit test {}'.format(os.path.basename(utest)))
        class_name, tests = process_unittest(utest, classes)
        if class_name is not None:
            test = {
                'filename': os.path.join(unittest_filename_prefix, os.path.basename(utest)),
                'tests': tests,
            }
            
            if class_name in all_tests:
                all_tests[class_name].append(test)
            else:
                all_tests[class_name] = [test]
    
    if write_unittests:
        for klass, tests in all_tests.items():
            data = {
                'info': info,
                'class': klass,
                'tests': tests,
            }
            ptrn = klass.lower() if ptrn_filenames_lowercase else klass
            render(data, tpl_unittest_source, tpl_unittest_target_ptrn.format(ptrn))
        
        # copy unit test files, if any
        if unittest_copyfiles is not None:
            for utfile in unittest_copyfiles:
                if os.path.exists(utfile):
                    tgt = os.path.join(unittest_copyfiles_base, os.path.basename(utfile))
                    log0("-->  Copying unittest file {} to {}".format(os.path.basename(utfile), tgt))
                    shutil.copyfile(utfile, tgt)
    else:
        log1('oo>  Not writing unit tests')


def process_unittest(path, classes):
    """ Process a unit test file at the given path, determining class structure
    from the given classes dict.
    
    :returns: A tuple with (top-class-name, [test-dictionaries])
    """
    utest = None
    assert(os.path.exists(path))
    with io.open(path, 'r', encoding='utf-8') as handle:
        utest = json.load(handle)
    assert(utest != None)
    
    # find the class
    className = utest.get('resourceType')
    assert(className != None)
    del utest['resourceType']
    klass = classes.get(className)
    if klass is None:
        log0('xx>  There is no class for "{}"'.format(className))
        return None, None
    
    # TODO: some "subclasses" like Age are empty because all their definitons are in their parent (Quantity). This
    # means that later on, the property lookup fails to find the properties for "Age", so fix this please.
    
    # gather testable properties
    tests = process_unittest_properties(utest, klass, classes)
    return className, sorted(tests, key=lambda x: x['path'])


def process_unittest_properties(utest, klass, classes, prefix=None):
    """ Process one level of unit test properties interpreted for the given
    class.
    """
    assert(klass != None)
    
    props = {}
    for cp in klass.get('properties', []):      # could cache this, but... lazy
        props[cp['name']] = cp
    
    # loop item's properties
    tests = []
    for key, val in utest.items():
        prop = props.get(key)
        if prop is None:
            log1('xxx>  Unknown property "{}" in unit test on {}'.format(key, klass.get('className')))
        else:
            propClass = prop['className']
            path = unittest_format_path_key.format(prefix, key) if prefix else key
            
            # property is an array
            if list == type(val):
                i = 0
                for v in val:
                    mypath = unittest_format_path_index.format(path, i)
                    tests.extend(handle_unittest_property(mypath, v, propClass, classes))
                    i += 1
            else:
                tests.extend(handle_unittest_property(unittest_format_path_prepare.format(path), val, propClass, classes))
    
    return tests


def handle_unittest_property(path, value, klass, classes):
    assert(path is not None)
    assert(value is not None)
    assert(klass is not None)
    tests = []
    
    # property is another element, recurse
    if dict == type(value):
        subklass = classes.get(subclassmap[klass] if klass in subclassmap else klass)
        if subklass is None:
            log1('xxx>  No class {} found for "{}"'.format(klass, path))
        else:
            tests.extend(process_unittest_properties(value, subklass, classes, path))
    else:
        isstr = isinstance(value, str)
        if not isstr and sys.version_info[0] < 3:       # Python 2.x has 'str' and 'unicode'
            isstr = isinstance(value, basestring)
            
        tests.append({'path': path, 'class': klass, 'value': value.replace("\n", "\\n") if isstr else value})
    
    return tests


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


def _camelCase(string, splitter='_'):
    """ Turns a string into CamelCase form without changing the first part's
    case.
    """
    if not string:
        return None
    
    name = ''
    i = 0
    for n in string.split(splitter):
        if i > 0:
            name += n[0].upper() + n[1:]
        else:
            name = n
        i += 1
    
    return name

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
    logging.basicConfig(level=logging.DEBUG)
    
    # start from scratch?
    if len(sys.argv) > 1 and '-f' == sys.argv[1]:
        if os.path.isdir(cache):
            shutil.rmtree(cache)
    
    # download spec if needed and extract
    path_spec = os.path.join(cache, os.path.split(specification_url)[1])
    expanded_spec = os.path.dirname(path_spec)
    source_dir = os.path.join(expanded_spec, 'site')
    
    if not os.path.exists(source_dir):
        if not os.path.isdir(cache):
            os.mkdir(cache)
        download(specification_url, path_spec)
        expand(path_spec, expanded_spec)
    else:
        logging.info('Using cached FHIR spec, supply "-f" to re-download')
    
    # parse
    parse(source_dir)

