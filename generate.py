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
    parser.add_argument('--ln', required=True, help='Choose the language', choices=['python', 'swift'])
    parser.add_argument('--cache', help='The path to the directory with all downloaded files', default='downloads')
    parser.add_argument('--output', help='The path to the directory with all generated models', default='models')
    return parser


if '__main__' == __name__:
    params = vars(args().parse_args())

    if params['ln'] == 'python':
        from Python import settings
    elif params['ln'] == 'swift':
        from Swift import settings
    else:
        sys.exit(1)

    # assure we have all files
    loader = fhirloader.FHIRLoader(settings, params['cache'])
    spec_source = loader.load(params['force'])

    # parse
    spec = fhirspec.FHIRSpec(spec_source, settings)
    spec.write(os.path.expanduser(params['output']))
