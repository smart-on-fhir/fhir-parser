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
        self.classes = {}               # class-name: FHIRClass()
        
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
    
    def announce_class(self, fhir_class):
        assert fhir_class.name
        if fhir_class.name in self.classes:
            logging.warning("Already have class {}".format(fhir_class.name))
        else:
            logging.debug("Found new class \"{}\"".format(fhir_class.name))
            self.classes[fhir_class.name] = fhir_class
        
        
    

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
        
        # extract all elements
        logging.info('Parsing profile {}  -->  {}'.format(self.filename, self.name))
        self.elements = []
        for elem_dict in self.structure.raw_elements:
            element = FHIRProfileElement(self, elem_dict)
            self.elements.append(element)
            
            # collect all that will become classes
            klass = element.as_class()
            if klass is not None:
                self.spec.announce_class(klass)
        
        # add properties to classes
        for element in self.elements:
            pass
        


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
        self.class_path = None
        self.name = None
        self.definition = None
        self._defines_class = None
        
        if element_dict is not None:
            self.parse_from(element_dict)
    
    def parse_from(self, element_dict):
        self.element_path = element_dict['path']
        parts = self.element_path.split('.')
        self.class_path = '.'.join(parts[:-1]) if len(parts) > 1 else parts[0]
        self.name = parts[-1]
        self.definition = FHIRElementDefinition(element_dict.get('definition'))
    
    @property
    def defines_class(self):
        """ Whether or not the element describes a *class*.
        
        An element wants a class if its type(s) contain a profile or if the
        element has the same path as the profile structure's type.
        """
        if self._defines_class is None:
            self.determine_type()
        return self._defines_class
    
    def determine_type(self):
        # element is the main profile structure type: class
        if self.element_path == self.class_path:
            self._defines_class = True
        
        # types declare a profile: class
        elif self.definition.has_profile_type():
            self._defines_class = True
    
    def as_class(self):
        """ If the element wants a *class*, returns a FHIRClass instance,
        None otherwise.
        
        An element is a class if its type(s) contain a profile or if the
        element has the same path as the profile structure's type.
        """
        if self.defines_class:
            return FHIRClass(self)
        return None
    
    def as_property(self):
        """ If the element describes a *class property*, returns a
        FHIRClassProperty instance, None otherwise.
        """
        if self.name in self.profile.skip_properties:
            logging.debug('Skipping property {}'.format(self.name))
            return None
        
        return None


class FHIRElementDefinition(object):
    """ The definition part of a FHIR element.
    """
    
    def __init__(self, definition_dict):
        self.types = []
        self.short = None
        self.formal = None
        self.comment = None
        self.n_min = None
        self.n_max = None
        self.constraint = None
        self.mapping = None
        
        if definition_dict is not None:
            self.parse_from(definition_dict)
    
    def parse_from(self, definition_dict):
        self.types = []
        for type_dict in definition_dict.get('type', []):
            self.types.append(FHIRElementType(type_dict))
        
        self.short = definition_dict['short']
        self.formal = definition_dict['formal']
        if self.formal and self.short == self.formal[:-1]:     # formal adds a trailing period
            self.formal = None
        self.comment = definition_dict.get('comments')
        
        self.n_min = definition_dict['min']
        self.n_max = definition_dict['max']
        if 'constraint' in definition_dict:
            self.constraint = FHIRElementConstraint(definition_dict['constraint'])
        if 'mapping' in definition_dict:
            self.mapping = FHIRElementMapping(definition_dict['mapping'])
    
    def has_profile_type(self):
        for typ in self.types:
            if typ.has_profile:
                return True
        return False



class FHIRElementType(object):
    """ The type(s) of an element.
    """
    
    def __init__(self, type_dict):
        self.code = None
        self.profile = None
        
        if type_dict is not None:
            self.parse_from(type_dict)
    
    def parse_from(self, type_dict):
        self.code = type_dict.get('code')
        self.profile = type_dict.get('profile')
    
    @property
    def has_profile(self):
        return self.profile is not None


class FHIRElementConstraint(object):
    """ Constraint on an element.
    """
    def __init__(self, constraint_arr):
        pass


class FHIRElementMapping(object):
    """ Mapping FHIR to other standards.
    """
    def __init__(self, mapping_arr):
        pass



class FHIRClass(object):
    """ An element/resource that should become its own class.
    """
    
    def __init__(self, element):
        assert isinstance(element, FHIRProfileElement)
        self.path = element.element_path
        self.name = ''.join(['{}{}'.format(s[:1].upper(), s[1:]) for s in self.path.split('.')])
        self.short = element.definition.short
        self.formal = element.definition.formal
        self.properties = []
        
#        'superclass': classmap.get(types[0][0], resource_default_base) if len(types) > 0 else resource_default_base,
    
    def add_property(self, prop):
        assert isinstance(prop, FHIRClassProperty)
        
    
    @property
    def hasNonoptional(self):
        return False


class FHIRClassProperty(object):
    """ An element describing a class property.
    """
    pass




class FHIRSearchParam(object):
    """ A FHIR search param, belonging to a profile.
    """
    pass
