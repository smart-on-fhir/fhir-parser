#!/usr/bin/env python
# -*- coding: utf-8 -*-

import io
import os
import glob
import json
import logging
import datetime

import fhirclass
import fhirrenderer

skip_because_unsupported = [
    'cda-clinicaldocument.profile.json',                # does not specify its name, overwriting its base profile
    'cda-inFulFillmentOf.profile.json',                 # does not specify its name, overwriting its base profile
    'cda-location.profile.json',                        # does not specify its name, overwriting its base profile
    'cda-organization.profile.json',                    # does not specify its name, overwriting its base profile
    'cda-patient-role.profile.json',                    # does not specify its name, overwriting its base profile
    'xds-documentmanifest.profile.json',                # does not specify its name, overwriting its base profile
    'xds-documentreference.profile.json',               # does not specify its name, overwriting its base profile
]


class FHIRSpec(object):
    """ The FHIR specification.
    """
    
    def __init__(self, directory, settings):
        assert os.path.isdir(directory)
        assert settings is not None
        self.directory = directory
        self.settings = settings
        self.info = FHIRVersionInfo(self, directory)
        self.profiles = {}              # profile-name: FHIRProfile()
        self.classes = {}               # class-name: FHIRClass()
        
        self.prepare()
        self.read_profiles()
        self.finalize()
    
    def prepare(self):
        """ Run actions before starting to parse profiles.
        """
        self.handle_manual_profiles()
    
    def read_profiles(self):
        """ Find all (JSON) profile files and instantiate into FHIRProfile.
        """
        for prof in glob.glob(os.path.join(self.directory, '*.profile.json')):
            if os.path.basename(prof) in skip_because_unsupported:
                continue
            
            profile = FHIRProfile(self, prof)
            self.found_profile(profile)
    
    def found_profile(self, profile):
            if not profile or not profile.name:
                raise Exception("No name for profile {}".format(prof))
            elif profile.name in self.profiles:
                logging.warning("Already have profile {}".format(profile.name))
            else:
                self.profiles[profile.name] = profile
    
    def has_profile(self, profile_name):
        return profile_name in self.profiles
    
    def handle_manual_profiles(self):
        """ Creates in-memory representations for all our manually defined
        profiles.
        """
        for filepath, module, contains in self.settings.manual_profiles:
            for contained in contains:
                profile = FHIRProfile(self, None)
                profile.structure = FHIRProfileStructure(profile, {'type': contained})
                self.found_profile(profile)
                
                element = FHIRProfileElement(profile, {'path': contained})
                manual_class = fhirclass.FHIRClass(element)
                manual_class.superclass_name = 'foo'
                self.announce_class(manual_class)
                # TODO: handle module name
    
    def finalize(self):
        """ Should be called after all profiles have been parsed and allows
        to perform additional actions, like looking up class implementations
        from different profiles.
        """
        for key, prof in self.profiles.items():
            prof.finalize()
    
    
    # MARK: Handling Classes
    
    def announce_class(self, fhir_class):
        assert fhir_class.name
        if fhir_class.name == fhir_class.superclass_name:
            raise Exception('Trying to announce class "{}" with itself as superclass'.format(fhir_class.name))
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
    
    
    # MARK: Naming Utilities
    
    def as_module_name(self, name):
        return name.lower() if name and self.settings.resource_modules_lowercase else name
    
    def as_class_name(self, classname):
        if not classname or len(classname) < 2:
            raise Exception('Class names should at least be 2 chars long, have "{}"'.format(classname))
        uppercased = classname[:1].upper() + classname[1:]
        return uppercased
    
    def class_name_for_type(self, type_name, main_resource=False):
        if type_name is None:
            if main_resource:
                return self.settings.resource_default_base
            return self.settings.contained_default_base
        mapped = self.settings.classmap.get(type_name, type_name)
        return self.as_class_name(mapped)
    
    def class_name_for_profile(self, profile_name):
        if not profile_name:
            return None
        type_name = profile_name.split('/')[-1]     # may be the full Profile URI, like http://hl7.org/fhir/Profile/MyProfile
        return self.class_name_for_type(type_name)
    
    def class_name_is_native(self, class_name):
        return True if class_name in self.settings.natives else False
    
    def safe_property_name(self, prop_name):
        return self.settings.reservedmap.get(prop_name, prop_name)
    
    def json_class_for_class_name(self, class_name):
        return self.settings.jsonmap.get(class_name, self.settings.jsonmap_default)
    
    @property
    def star_expand_types(self):
        return self.settings.starexpandtypes
    
    
    # MARK: Writing Data
    
    def write(self):
        if self.settings.write_resources:
            renderer = fhirrenderer.FHIRProfileRenderer(self, self.settings)
            renderer.copy_files()
            renderer.render()
        
        if self.settings.write_factory:
            renderer = fhirrenderer.FHIRFactoryRenderer(self, self.settings)
            renderer.render()


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
        self.targetname = None
        self.structure = None
        self._element_map = {}
        self._class_map = {}
        self.classes = []
        self._did_finalize = False
        
        self.filepath = filepath
        self.filename = os.path.basename(filepath) if filepath else None
        
        if filepath is not None:
            assert os.path.exists(filepath)
            self.read_profile()
    
    @property
    def name(self):
        return self.structure.name if self.structure is not None else None
    
    def read_profile(self):
        """ Read the JSON definition of a profile from disk.
        """
        profile = None
        with io.open(self.filepath, 'r', encoding='utf-8') as handle:
            profile = json.load(handle)
        assert profile
        assert 'Profile' == profile['resourceType']
        
        # parse structure
        self.structure = FHIRProfileStructure(self, profile)
        logging.info('Parsing profile {}  -->  {}'.format(self.filename, self.name))
        if self.spec.has_profile(self.name):
            return
        
        # extract all elements
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
                self.targetname = element.name_if_class()
    
    
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
            klass = fhirclass.FHIRClass(element)
            self.found_class(klass)
        
        return klass
    
    def found_class(self, klass):
        self._class_map[klass.path] = klass
        self.classes.append(klass)
        self.spec.announce_class(klass)
    
    def needed_external_classes(self):
        """ Returns a unique list of class items that are needed for any of the
        receiver's classes' properties and are not defined in this profile.
        
        :raises: Will raise if called before `finalize` has been called.
        """
        if not self._did_finalize:
            raise Exception('Cannot use `needed_external_classes` before finalizing')
        
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
                prop_cls_name = prop.class_name
                if prop_cls_name not in checked and not self.spec.class_name_is_native(prop_cls_name):
                    prop_cls = self.spec.class_announced_as(prop_cls_name)
                    checked.add(prop_cls_name)
                    if prop_cls is None:
                        # TODO: turn into exception once `nameReference` on element definition is implemented
                        logging.error('There is no class "{}" for property "{}" on "{}" in {}'.format(prop_cls_name, prop.name, klass.name, self.name))
                    else:
                        prop.module_name = prop_cls.module
                        needs.append(prop_cls)
                
                # is the property a reference to a certain class?
                ref_cls = prop.reference_to
                if ref_cls is not None and ref_cls.name not in checked:
                    checked.add(ref_cls.name)
                    needs.append(ref_cls)
        
        return sorted(needs, key=lambda n: n.module)
    
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
            if cls.superclass is None:
                super_cls = self.spec.class_announced_as(cls.superclass_name)
                if super_cls is None:
                    # TODO: turn into exception once we have all basic types and can parse all special cases (like "#class")
                    logging.error('There is no class implementation for class named "{}" in profile "{}"'
                        .format(cls.superclass_name, self.name))
                else:
                    cls.superclass = super_cls
            
            for prop in cls.properties:
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
        self.type = json_dict.get('type')
        self.name = json_dict.get('name')
        if self.name is None:
            self.name = self.type
        self.base = json_dict.get('base')
        if self.base:
            self.subclass_of = self.profile.spec.class_name_for_profile(self.base)
        
        # find element definitions
        if self.base:
            self.raw_elements = json_dict['differential'].get('element', [])
        elif 'snapshot' in json_dict:
            self.raw_elements = json_dict['snapshot'].get('element', [])


class FHIRProfileElement(object):
    """ An element in a profile's structure.
    """
    
    def __init__(self, profile, element_dict):
        assert isinstance(profile, FHIRProfile)
        self.profile = profile
        self.path = None
        self.parent = None
        self.parent_name = None
        self.name = None
        self.definition = None
        self.is_main_profile_resource = False
        self.is_resource = False
        
        if element_dict is not None:
            self.parse_from(element_dict)
        else:
            self.definition = FHIRElementDefinition(self, None)
    
    def parse_from(self, element_dict):
        self.path = element_dict['path']
        if self.path == self.profile.structure.type:
            self.is_main_profile_resource = True
            if not self.profile.structure.base or 'resource' in self.profile.structure.base.lower():
                self.is_resource = True
        
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
            logging.warning('Element {} does not have a definition, skipping'.format(self.path))
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
                    for exp_type in self.profile.spec.star_expand_types:
                        props.append(fhirclass.FHIRClassProperty(exp_type, type_obj))
                else:
                    props.append(fhirclass.FHIRClassProperty(type_obj.code, type_obj))
            return props
        
        # no `type` definition in the element: it's an inline class definition
        type_obj = FHIRElementType(self.definition, None)
        return [fhirclass.FHIRClassProperty(self.name_if_class(), type_obj)]
        
    
    # MARK: Name Utils
    
    def name_of_resource(self):
        """ Returns the name of the resource this element defines, if it does
        so, `None` otherwise.
        """
        if not self.is_resource:
            return None
        return self.path if self.profile and self.path == self.profile.name else None
    
    def name_if_class(self):
        if self.parent is None and '.' in self.path:
            raise Exception('Must have a parent FHIRProfileElement for "{}"'.format(self.path))
        
        classname = self.profile.spec.class_name_for_type(self.name)
        if self.parent is not None:
            return self.parent.name_if_class() + classname
        return classname
    
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
        # else type stays None, which will apply the default class name
        
        return self.profile.spec.class_name_for_type(type_code, self.is_main_profile_resource)


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
        # TODO: extract "nameReference"
        
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


