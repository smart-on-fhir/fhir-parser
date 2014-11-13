#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import io
import glob
import json
import logging
import datetime

import fhirrenderer

import settings as _settings

skip_because_unsupported = [
    'diagnosticreport-profile-lipids.profile.json',
    'familyhistory-genetics-pedigree.profile.json',
]


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
            if os.path.basename(prof) in skip_because_unsupported:
                continue
            
            profile = FHIRProfile(self, prof)
            if not profile.name:
                logging.warning("No name for profile {}".format(prof))
            elif profile.name in self.profiles:
                logging.warning("Already have profile {}".format(profile.name))
            else:
                self.profiles[profile.name] = profile
    
    def announce_class(self, fhir_class):
        assert fhir_class.path
        if fhir_class.path in self.classes:
            logging.warning("Already have class {}".format(fhir_class.name))
        else:
            logging.info("New class \"{}\" for {}, subclass of {}".format(fhir_class.name, fhir_class.resource_name, fhir_class.superclass))
            self.classes[fhir_class.path] = fhir_class
    
    def class_announced_as(self, class_announce):
        if class_announce in self.classes:
            return self.classes[class_announce]
        return None
    
    def write(self):
        if _settings.write_resources:
            renderer = fhirrenderer.FHIRProfileRenderer(self, _settings)
            for pname, profile in self.profiles.items():
                renderer.render(profile)


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
        self.requirements = None
        self.structure = None
        self.elements = []
        self.classes = []
        
        self.read_profile()
    
    def read_profile(self):
        profile = None
        with io.open(self.filepath, 'r', encoding='utf-8') as handle:
            profile = json.load(handle)
        assert profile
        assert 'Profile' == profile['resourceType']
        
        self.requirements = profile.get('requirements')

        # parse structure
        structure_arr = profile.get('structure')
        if structure_arr is None or 0 == len(structure_arr):
            logging.warning('Profile {} has no structure'.format(self.filepath))
            return
        
        self.structure = FHIRProfileStructure(self, structure_arr[0])
        self.name = self.structure.name
        
        # extract all elements
        logging.info('Parsing profile {}  -->  {}'.format(self.filename, self.name))
        self.elements = []
        for elem_dict in self.structure.raw_elements:
            element = FHIRProfileElement(self, elem_dict)
            self.elements.append(element)
            
            # collect all that will become classes
            klass = element.as_class()
            if klass is not None:
                self.found_class(klass)
        
        # convert elements to properties and add them to their respective classes
        for element in self.elements:
            properties = element.as_property_list()
            if properties is not None:
                for prop in properties:
                    klass = self.find_class(prop.for_class)
                    if klass is None:
                        raise Exception("Need class \"{}\" for property {}, but don't have it".format(prop.for_class, prop.path))
                    
                    klass.add_property(prop)
    
    def found_class(self, klass):
        self.classes.append(klass)
        self.spec.announce_class(klass)
    
    def find_class(self, klass):
        return self.spec.class_announced_as(klass)


class FHIRProfileStructure(object):
    """ The actual structure of a profile.
    """
    
    def __init__(self, profile, structure_dict):
        self.profile = profile
        self.type = None
        self.name = None
        self.is_subclass = False
        self.raw_elements = None
        
        self.parse_from(structure_dict)
    
    def parse_from(self, structure_dict):
        self.type = structure_dict.get('type')
        self.name = structure_dict.get('name')
        if self.name is None:
            self.name = self.type
        elif self.name != self.type:
            self.is_subclass = True
        
        # find element definitions
        if 'snapshot' in structure_dict:
            self.raw_elements = structure_dict['snapshot'].get('element', [])     # 0.3 (or nightly)
        else:
            self.raw_elements = structure_dict.get('element', [])                 # 0.28


class FHIRProfileElement(object):
    """ An element in a profile's structure.
    """
    
    def __init__(self, profile, element_dict):
        self.profile = profile
        self.path = None
        self.class_path = None
        self.name = None
        self.definition = None
        self.is_main_profile_resource = False
        self._defines_class = None
        
        if element_dict is not None:
            self.parse_from(element_dict)
    
    def parse_from(self, element_dict):
        self.path = element_dict['path']
        parts = self.path.split('.')
        self.class_path = '.'.join(parts[:-1]) if len(parts) > 1 else parts[0]
        # TODO: respect an element's "name" attribute
        self.name = parts[-1]
        if 'definition' in element_dict:
            self.definition = FHIRElementDefinition(self, element_dict['definition'])
        self.is_main_profile_resource = True if self.path == self.class_path else False
    
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
        if self.is_main_profile_resource:
            logging.debug("{} defines a class because it describes the profile's main resource".format(self.name))
            self._defines_class = True
        
        # types declare a profile: class
        elif self.definition is not None and 0 == len(self.definition.types):
            logging.debug("{} defines a class because it doesn't have a type".format(self.name))
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
    
    def as_property_list(self):
        """ If the element describes a *class property*, returns a list of
        FHIRClassProperty instances, None otherwise.
        """
        if self.is_main_profile_resource or self.definition is None:
            return None
        
        if self.name in self.profile.skip_properties:
            logging.debug('Skipping property {}'.format(self.name))
            return None
        
        return FHIRClassProperty.for_element(self)
    
    def name_for_class(self):
        base = self.name if self.name and not '.' in self.path else self.path
        return ''.join(['{}{}'.format(s[:1].upper(), s[1:]) for s in base.split('.')])


class FHIRElementDefinition(object):
    """ The definition part of a FHIR element.
    """
    
    def __init__(self, element, definition_dict):
        self.element = element
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
            self.types.append(FHIRElementType(self, type_dict))
        
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


class FHIRElementType(object):
    """ The type(s) of an element.
    """
    
    def __init__(self, definition, type_dict):
        assert isinstance(definition, FHIRElementDefinition)
        self.definition = definition
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
        tps = element.definition.types
        assert len(tps) < 2
        
        self.path = element.path
        self.name = element.name_for_class()
        self.resource_name = element.path if element.path == element.profile.name else None
        self.superclass = _settings.classmap.get(tps[0].code, _settings.resource_default_base) if len(tps) > 0 else _settings.resource_default_base
        self.short = element.definition.short
        if element.is_main_profile_resource:
            self.formal = element.profile.requirements
        else:
            self.formal = element.definition.formal
        self.properties = []
    
    def add_property(self, prop):
        assert isinstance(prop, FHIRClassProperty)
        prop.klass = self
        self.properties.append(prop)
        self.properties = sorted(self.properties, key=lambda x: x.name)
    
    @property
    def has_nonoptional(self):
        for prop in self.properties:
            if prop.nonoptional:
                return True
        return False


class FHIRClassProperty(object):
    """ An element describing a class property.
    """
    
    @classmethod
    def for_element(cls, element):
        """ Returns a list of instances (usually only one) that are represented
        by an element.
        """
        props = []
        if element.definition is None:
            logging.warning("Element {} does not have a definition, skipping".format(element.path))
            return props
        
        if len(element.definition.types) > 0:
            for type_obj in element.definition.types:
                # the wildcard type: expand to all possible types, as defined in our mapping
                if '*' == type_obj.code:
                    for exp_type in _settings.starexpandtypes:
                        props.append(cls(exp_type, type_obj))
                else:
                    props.append(cls(type_obj.code, type_obj))
        # no `type` definition in the element, it's an inline definition
        else:
            type_obj = FHIRElementType(element.definition, None)
            props.append(cls(element.name_for_class(), type_obj))
        
        return props
    
    def __init__(self, type_name, type_obj):
        assert isinstance(type_obj, FHIRElementType)
        
        self.path = type_obj.definition.element.path
        name = type_obj.definition.element.name
        if '[x]' in name:
            # TODO: "MedicationPrescription.reason[x]" can be a
            # "ResourceReference" but apparently should be called
            # "reasonResource", NOT "reasonResourceReference". This will be
            # changed in a later FHIR version.
            kl = 'Resource' if 'ResourceReference' == type_name else type_name
            name = name.replace('[x]', '{}{}'.format(kl[:1].upper(), kl[1:]))
        
        self.orig_name = name
        self.name = _settings.reservedmap.get(name, name)
        self.for_class = type_obj.definition.element.class_path
        self.class_name = _settings.classmap.get(type_name, type_name)
        self.klass = None       # will be set when adding to class
        self.json_class = _settings.jsonmap.get(self.class_name, _settings.jsonmap_default)
        self.is_native = True if self.class_name in _settings.natives else False
        self.is_array = True if '*' == type_obj.definition.n_max else False
        self.nonoptional = True if 0 != int(type_obj.definition.n_min) else False
        self.reference = type_obj.profile
        self.short = type_obj.definition.short
    
    @property
    def is_reference_to(self):
        if self.reference:
            ref = self.reference.replace('http://hl7.org/fhir/profiles/', '')
            return _settings.classmap.get(ref, ref)
        return None



class FHIRSearchParam(object):
    """ A FHIR search param, belonging to a profile.
    """
    pass
