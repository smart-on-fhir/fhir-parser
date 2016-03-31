#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  Download and parse FHIR resource definitions


import sys
import os
import fhirloader
import fhirspec
import argparse


def args():
    parser = argparse.ArgumentParser(description='FHIR models generator')
    parser.add_argument('-f', '--force', action='store_true', help='To force a redownload of the spec')
    parser.add_argument('-r', '--resources', action='store_true', help='Generate resource models')
    parser.add_argument('-e', '--element_factory', action='store_true', help='Generate elementfactory')
    parser.add_argument('-t', '--tests', action='store_true', help='Generate tests')
    parser.add_argument('--ln', required=True, help='Choose the language', choices=['python', 'swift'])
    parser.add_argument('--cache', help='The path to the directory with all downloaded files', default='downloads')
    parser.add_argument('--output', help='The path to the directory with all generated models', default='models')
    return parser


if '__main__' == __name__:
    params = vars(args().parse_args())

    if params['ln'] == 'python':
        from Python import settings
        settings.write_resources = params['resources']
        settings.write_factory = params['element_factory']
        settings.write_unittests = params['tests']
    elif params['ln'] == 'swift':
        from Swift import settings
        settings.write_resources = params['resources']
        settings.write_factory = params['resources']
        settings.write_unittests = params['tests']
    else:
        sys.exit(1)

    # assure we have all files
    loader = fhirloader.FHIRLoader(settings, params['cache'])
    spec_source = loader.load(params['force'])

    # parse
    spec = fhirspec.FHIRSpec(spec_source, settings)
    spec.write(os.path.expanduser(params['output']))
