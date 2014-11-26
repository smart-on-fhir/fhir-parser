#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import glob
import json
import logging
import datetime

import fhirrenderer

import settings as _settings

skip_because_unsupported = [
    'observation-device-metric-devicemetricobservation.profile.json',       # has typo "Speciment"
    'dr-uslab-uslabdr.profile.json',                                        # invalid property name
    'encounter-daf-encounter-daf.profile.json',                             # invalid property path
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
        
        self.prepare()
        self.read_profiles()
        self.finalize()
    
    def prepare(self):
        """ Run actions before starting to parse profiles.
        """
        self.create_base_classes()
    
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
    
    def finalize(self):
        """ Should be called after all profiles have been parsed and allows
        to perform additional actions, like looking up class implementations
        from different profiles.
        """
        for key, prof in self.profiles.items():
            prof.finalize()
    
    
    # MARK: Handling Classes
    
    def create_base_classes(self):
        """ Creates in-memory representations for all our base classes.
        """
        for filepath, module, contains in _settings.resource_baseclasses:
            for contained in contains:
                element = FHIRProfileElement(None, None)
                element.path = contained
                element.name = contained
                self.announce_class(FHIRClass(element))
    
    def announce_class(self, fhir_class):
        assert fhir_class.name
        if fhir_class.name in self.classes:
            logging.warning("Already have class {}".format(fhir_class.name))
        else:
            if fhir_class.resource_name:
                logging.debug('New resource class "{}" describing "{}", subclass of {}'.format(fhir_class.name, fhir_class.resource_name, fhir_class.superclass_name))
            else:
                logging.debug('New element class "{}", subclass of {}'.format(fhir_class.name, fhir_class.superclass_name))
            self.classes[fhir_class.name] = fhir_class
    
    def class_announced_as(self, class_name):
        if class_name in self.classes:
            return self.classes[class_name]
        return None
    
    
    # MARK: Writing Data
    
    def write(self):
        if _settings.write_resources:
            renderer = fhirrenderer.FHIRProfileRenderer(self, _settings)
            renderer.copy_files()
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
        with open(filepath, 'r', encoding='utf-8') as handle:
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
        self.targetname = None
        self.structure = None
        self._element_map = {}
        self._class_map = {}
        self.classes = []
        self._did_finalize = False
        
        self.read_profile()
    
    @property
    def name(self):
        return self.structure.name if self.structure is not None else None
    
    def read_profile(self):
        profile = None
        with open(self.filepath, 'r', encoding='utf-8') as handle:
            profile = json.load(handle)
        assert profile
        assert 'Profile' == profile['resourceType']
        
        # parse structure
        self.structure = FHIRProfileStructure(self, profile)
        
        # extract all elements
        logging.info('Parsing profile {}  -->  {}'.format(self.filename, self.name))
        self._element_map = {}
        for elem_dict in self.structure.raw_elements:
            element = FHIRProfileElement(self, elem_dict)
            self._element_map[element.path] = element
            
            # establish hierarchy (may move to extra loop in case elements are no longer in order)
            element.parent = self._element_map.get(element.parent_name)
        
        # create classes and class properties
        for epath, element in self._element_map.items():
            if element.is_main_profile_resource:
                self.class_for_element(element)         # to ensure we have the main class
            
            properties = element.as_properties()
            if properties is not None:
                for prop in properties:
                    klass = self.class_for_parent_of(element)
                    klass.add_property(prop)
            
            if element.is_main_profile_resource:
                self.targetname = element.name_for_class()

    
    # MARK: Class Handling
    
    def class_for_parent_of(self, element):
        if not element.parent_name:
            return None
        
        parent = self._element_map.get(element.parent_name)
        if parent is None:
            raise Exception('Need element "{}" for property "{}", but don\'t have it'.format(element.parent_name, element.path))
        
        assert element.parent_name == parent.path
        return self.class_for_element(parent)
    
    def class_for_element(self, element):
        klass = self._class_map.get(element.path)
        if klass is None:
            klass = FHIRClass(element)
            self.found_class(klass)
        
        return klass
    
    def found_class(self, klass):
        self._class_map[klass.path] = klass
        self.classes.append(klass)
        self.spec.announce_class(klass)
    
    def needs_classes(self):
        """ Returns a unique list of class items that are needed for any of the
        receiver's classes' properties and are not defined in this profile.
        
        :raises: Will raise if called before `finalize` has been called.
        """
        if not self._did_finalize:
            raise Exception('Cannot use `needs_classes` before finalizing')
        
        checked = set([c.name for c in self.classes])
        needs = []
        
        for klass in self.classes:
            # are there superclasses that we need to import?
            sup_cls = klass.superclass
            if sup_cls is not None and sup_cls.name not in checked:
                checked.add(sup_cls.name)
                needs.append(sup_cls)
            
            # look at all properties' classes
            for prop in klass.properties:
                prop_cls = prop.klass
                if prop_cls.name not in checked:
                    checked.add(prop_cls.name)
                    needs.append(prop_cls)
                
                # is the property a reference to a certain class?
                ref_cls = prop.reference_to
                if ref_cls is not None and ref_cls.name not in checked:
                    checked.add(ref_cls.name)
                    needs.append(ref_cls)
        
        return needs
    
    def writable_classes(self):
        classes = []
        for klass in self.classes:
            if klass.should_write():
                classes.append(klass)
        return classes
    
    
    # MARK: Finalizing
    
    def finalize(self):
        """ Our spec object calls this when all profiles have been parsed.
        """
        
        # assign all super-classes and reference-to-classes as objects
        for cls in self.classes:
            if cls.superclass_name and cls.superclass is None:
                super_cls = self.spec.class_announced_as(cls.superclass_name)
                if super_cls is None:
                    logging.error('There is no class implementation for class named "{}" in profile "{}"'
                        .format(cls.superclass_name, self.name))
                else:
                    cls.superclass = super_cls
            
            for prop in cls.properties:
                if prop.klass.superclass_name is not None and prop.klass.superclass is None:
                    super_cls = self.spec.class_announced_as(prop.klass.superclass_name)
                    if super_cls is None:
                        logging.error('There is no class implementation for class named "{}" on property "{}" on "{}"'
                            .format(prop.klass.superclass_name, prop.name, cls.name))
                    else:
                        prop.klass.superclass = super_cls
                
                if prop.reference_to_profile is not None:
                    ref_cls = self.spec.class_announced_as(prop.reference_to_name)
                    if ref_cls is None:
                        logging.error('There is no class implementation for class named "{}" on reference property "{}" on "{}"'
                            .format(prop.reference_to_name, prop.name, cls.name))
                    else:
                        prop.reference_to = ref_cls
        
        self._did_finalize = True


class FHIRProfileStructure(object):
    """ The actual structure of a complete profile.
    """
    
    def __init__(self, profile, profile_dict):
        self.profile = profile
        self.type = None
        self.name = None
        self.base = None
        self.subclass_of = None
        self.raw_elements = None
        
        self.parse_from(profile_dict)
    
    def parse_from(self, json_dict):
        # support < 0.3
        if 'structure' in json_dict:
            json_dict = json_dict['structure'][0]
        
        self.type = json_dict.get('type')
        self.name = json_dict.get('name')
        if self.name is None:
            self.name = self.type
        self.base = json_dict.get('base')
        if self.base:
            self.subclass_of = self.base.replace(_settings.fhir_namespace, '')
        
        # find element definitions
        if self.base:
            logging.debug('Using "differential" for {}'.format(self.name))
            self.raw_elements = json_dict['differential'].get('element', [])
        elif 'snapshot' in json_dict:
            self.raw_elements = json_dict['snapshot'].get('element', [])     # v0.3
        else:
            self.raw_elements = json_dict.get('element', [])                 # < v0.3


class FHIRProfileElement(object):
    """ An element in a profile's structure.
    """
    
    def __init__(self, profile, element_dict):
        self.profile = profile
        self.path = None
        self.parent = None
        self.parent_name = None
        self.name = None
        self.definition = None
        self.is_main_profile_resource = False
        
        if element_dict is not None:
            self.parse_from(element_dict)
        else:
            self.definition = FHIRElementDefinition(self, None)
    
    def parse_from(self, element_dict):
        self.path = element_dict['path']
        if self.path == self.profile.structure.type:
            self.is_main_profile_resource = True
        
        parts = self.path.split('.')
        self.parent_name = '.'.join(parts[:-1]) if len(parts) > 0 else None
        self.name = element_dict.get('name')
        
        # find the definition
        if 'definition' in element_dict:        # < v0.3
            self.definition = FHIRElementDefinition(self, element_dict['definition'])
            if self.is_main_profile_resource:
                self.name = self.profile.name
        else:                                   # v0.3
            self.definition = FHIRElementDefinition(self, element_dict)
        
        # handle the name
        if not self.name:
            self.name = parts[-1]
        if '-' in self.name:
            self.name = ''.join([n[:1].upper() + n[1:] for n in self.name.split('-')])
    
    def as_properties(self):
        """ If the element describes a *class property*, returns a list of
        FHIRClassProperty instances, None otherwise.
        """
        if self.is_main_profile_resource or self.definition is None:
            return None
        
        if self.name in self.profile.skip_properties:
            logging.debug('Skipping property "{}"'.format(self.name))
            return None
        
        if self.definition is None:
            logging.warning("Element {} does not have a definition, skipping".format(self.path))
            return None
        
        if self.definition.representation:
            logging.debug('Omitting property "{}" for representation {}'.format(self.name, self.definition.representation))
            return None
        
        # create a list of FHIRClassProperty instances (usually with only 1 item)
        if len(self.definition.types) > 0:
            props = []
            for type_obj in self.definition.types:
                # the wildcard type: expand to all possible types, as defined in our mapping
                if '*' == type_obj.code:
                    for exp_type in _settings.starexpandtypes:
                        props.append(FHIRClassProperty(exp_type, type_obj))
                else:
                    props.append(FHIRClassProperty(type_obj.code, type_obj))
            return props
        
        # no `type` definition in the element: it's an inline class definition
        type_obj = FHIRElementType(self.definition, None)
        return [FHIRClassProperty(self.name_for_class(), type_obj)]
        
    
    def name_of_resource(self):
        return self.path if self.profile and self.path == self.profile.name else None
    
    def name_for_class(self):
        if self.parent is None and '.' in self.path:
            raise Exception('Must have a parent FHIRProfileElement for "{}"'.format(self.path))
        uppercased = self.name[:1].upper() + self.name[1:]
        if self.parent is not None:
            return self.parent.name_for_class() + uppercased
        return uppercased
    
    def name_for_superclass(self):
        """ Determine the superclass for the element (used for class elements).
        """
        tps = self.definition.types
        assert len(tps) < 2
        type_code = None
        
        if self.is_main_profile_resource and self.profile.structure.subclass_of is not None:
            type_code = self.profile.structure.subclass_of
        elif self.is_main_profile_resource and self.name != self.path:
            type_code = self.path
        elif len(tps) > 0:
            type_code = tps[0].code
        else:
            type_code = _settings.resource_default_base
        
        return _settings.classmap.get(type_code, type_code)


class FHIRElementDefinition(object):
    """ The definition of a FHIR element.
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
        self.representation = None
        # TODO: extract "defaultValue[x]", "fixed[x]", "pattern[x]"
        
        if definition_dict is not None:
            self.parse_from(definition_dict)
    
    def parse_from(self, definition_dict):
        self.types = []
        for type_dict in definition_dict.get('type', []):
            self.types.append(FHIRElementType(self, type_dict))
        
        self.short = definition_dict.get('short')
        self.formal = definition_dict.get('formal')
        if self.formal and self.short == self.formal[:-1]:     # formal adds a trailing period
            self.formal = None
        self.comment = definition_dict.get('comments')
        
        self.n_min = definition_dict.get('min')
        self.n_max = definition_dict.get('max')
        if 'constraint' in definition_dict:
            self.constraint = FHIRElementConstraint(definition_dict['constraint'])
        if 'mapping' in definition_dict:
            self.mapping = FHIRElementMapping(definition_dict['mapping'])
        self.representation = definition_dict.get('representation')


class FHIRElementType(object):
    """ Representing a type of an element.
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
    
    def elements_parent_name(self):
        return self.definition.element.parent_name


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
        
        self.path = element.path
        self.name = element.name_for_class()
        self.module = self.name.lower() if _settings.resource_modules_lowercase else self.name
        self.resource_name = element.name_of_resource()
        self.superclass = None
        self.superclass_name = element.name_for_superclass()
        self.short = element.definition.short
        self.formal = element.definition.formal
        self.properties = []
    
    def add_property(self, prop):
        """ Add a property to the receiver.
        """
        assert isinstance(prop, FHIRClassProperty)
        
        # do we already have a property with this name?
        # if we do and it's a specific reference, make it a reference to a
        # generic resource
        for existing in self.properties:
            if existing.name == prop.name:
                if not existing.reference_to_profile:
                    raise Exception('Already have property "{}" on "{}", which is only allowed for references'.format(prop.name, self.name))
                
                existing.reference_to_profile = 'Resource'
                return
        
        prop.klass = self
        self.properties.append(prop)
        self.properties = sorted(self.properties, key=lambda x: x.name)
    
    def should_write(self):
        if self.superclass is not None:
            return True
        return True if len(self.properties) > 0 else False
    
    @property
    def has_nonoptional(self):
        for prop in self.properties:
            if prop.nonoptional:
                return True
        return False


class FHIRClassProperty(object):
    """ An element describing an instance property.
    """
    
    def __init__(self, type_name, type_obj):
        assert isinstance(type_obj, FHIRElementType)
        
        self.path = type_obj.definition.element.path
        name = type_obj.definition.element.name
        if '[x]' in name:
            # < v0.3: "MedicationPrescription.reason[x]" can be a
            # "ResourceReference" but apparently should be called
            # "reasonResource", NOT "reasonResourceReference".
            kl = 'Resource' if 'ResourceReference' == type_name else type_name  # < v0.3
            name = name.replace('[x]', '{}{}'.format(kl[:1].upper(), kl[1:]))
        
        self.orig_name = name
        self.name = _settings.reservedmap.get(name, name)
        self.parent_name = type_obj.elements_parent_name()
        self.class_name = _settings.classmap.get(type_name, type_name)
        self.klass = None       # will be set when adding to class
        self.json_class = _settings.jsonmap.get(self.class_name, _settings.jsonmap_default)
        self.is_native = True if self.class_name in _settings.natives else False
        self.is_array = True if '*' == type_obj.definition.n_max else False
        self.nonoptional = True if type_obj.definition.n_min is not None and 0 != int(type_obj.definition.n_min) else False
        self.reference_to_profile = type_obj.profile
        self.reference_to = None
        self.short = type_obj.definition.short
    
    @property
    def reference_to_name(self):
        if self.reference_to_profile:
            ref = self.reference_to_profile.replace(_settings.fhir_namespace, '')
            return _settings.classmap.get(ref, ref)
        return None



class FHIRSearchParam(object):
    """ A FHIR search param, belonging to a profile.
    """
    pass
