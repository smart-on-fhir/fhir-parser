#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import io
import glob
import json
import logging
import datetime

from settings import *


class FHIRSpec(object):
    """ The FHIR specification.
    """
    
    def __init__(self, directory):
        assert os.path.isdir(directory)
        self.directory = directory
        self.info = FHIRVersionInfo(self, directory)
        self.profiles = {}              # profile-name: FHIRProfile()
        
        self.read_profiles()
    
    def read_profiles(self):
        """ Find all (JSON) profile files and instantiate into FHIRProfile.
        """
        assert 0 == len(self.profiles)
        for prof in glob.glob(os.path.join(self.directory, '*.profile.json')):
            profile = FHIRProfile(self, prof)
            if not profile.name:
                logging.warning("No name for profile {}".format(prof))
            elif profile.name in self.profiles:
                logging.warning("Already have profile {}".format(profile.name))
            else:
                self.profiles[profile.name] = profile
        
    

class FHIRVersionInfo(object):
    """ The version of a FHIR specification.
    """
    
    def __init__(self, spec, directory):
        self.spec = spec
        
        now = datetime.date.today()
        self.date = now.isoformat()
        self.year = now.year
        
        self.version = None
        infofile = os.path.join(directory, 'version.info')
        self.read_version(infofile)
    
    def read_version(self, filepath):
        assert os.path.isfile(filepath)
        with io.open(filepath, 'r', encoding='utf-8') as handle:
            text = handle.read()
            for line in text.split("\n"):
                if '=' in line:
                    (n, v) = line.strip().split('=', 2)
                    if 'FhirVersion' == n:
                        self.version = v


class FHIRProfile(object):
    """ One FHIR profile.
    """
    
    # properties with these names will be skipped as we implement them in our base classes
    skip_properties = [
        'extension',
        'modifierExtension',
        'language',
        'contained',
    ]
    
    def __init__(self, spec, filepath):
        self.spec = spec
        assert os.path.exists(filepath)
        self.filepath = filepath
        self.filename = os.path.basename(self.filepath)
        self.name = None
        self.structure = None
        self.elements = None
        
        self.read_profile()
    
    def read_profile(self):
        profile = None
        with io.open(self.filepath, 'r', encoding='utf-8') as handle:
            profile = json.load(handle)
        assert profile
        assert 'Profile' == profile['resourceType']
        
        structure_arr = profile.get('structure')
        if structure_arr is None or 0 == len(structure_arr):
            logging.warning('Profile {} has no structure'.format(self.filepath))
            return
        
        # parse structure
        self.structure = FHIRProfileStructure(self, structure_arr[0])
        self.name = self.structure.main
        
        # extract elements (= profile properties)
        logging.info('Parsing profile {}  -->  {}'.format(self.filename, self.name))
        self.elements = []
        for elem_dict in self.structure.raw_elements:
            self.elements.append(FHIRProfileElement(self, elem_dict))


class FHIRProfileStructure(object):
    """ The actual structure of a profile.
    """
    
    def __init__(self, profile, structure):
        self.profile = profile
        self.type = None
        self.main = None
        self.is_subclass = False
        self.raw_elements = None
        
        self.parse_from(structure)
    
    def parse_from(self, structure):
        self.type = structure.get('type')
        self.main = structure.get('name')
        if self.main is None:
            self.main = self.type
        elif self.main != self.type:
            self.is_subclass = True
        
        # find element definitions
        if 'snapshot' in structure:
            self.raw_elements = structure['snapshot'].get('element', [])     # 0.3 (or nightly)
        else:
            self.raw_elements = structure.get('element', [])                 # 0.28


class FHIRProfileElement(object):
    """ An element in a profile's structure.
    """
    
    def __init__(self, profile, element_dict):
        self.profile = profile
        self.element_path = None
        self.name = None
        
        self.parse_from(element_dict)
    
    def parse_from(self, element_dict):
        self.element_path = element_dict['path']
        parts = self.element_path.split('.')
        classpath = '.'.join(parts[:-1]) if len(parts) > 1 else parts[0]
        self.name = parts[-1]
        
        if self.name in self.profile.skip_properties:
            logging.debug('Skipping {} property'.format(self.name))
            return
        
        definition = element_dict.get('definition')
        if definition is None:
            logging.info('No definition for {}'.format(self.element_path))
            return
        
        k = self.profile.spec.profiles.get(classpath)
        # newklass = parse_elem(self.element_path, self.name, definition, k)
        
        # # element describes a new class
        # if newklass is not None:
        #     mapping[newklass['path']] = newklass
        #     classes.append(newklass)
            
        #     # is this the resource description itself?
        #     if self.element_path == main:
        #         newklass['resourceName'] = main
        #         newklass['formal'] = requirements
            
        #     # this is a "subclass", such as "Age" on "Quantity"
        #     elif is_subclass:
        #         log1('--->  Treating {} as subclass of {}'.format(main, superclass))
        #         newklass['className'] = main
        #         newklass['superclass'] = superclass
        #         newklass['is_subclass'] = True
        #         newklass['short'] = profile.get('name')
        #         newklass['formal'] = profile.get('description')


class FHIRSearchParam(object):
    """ A FHIR search param, belonging to a profile.
    """
    pass
