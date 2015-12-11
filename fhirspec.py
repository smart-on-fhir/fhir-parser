#!/usr/bin/env python
# -*- coding: utf-8 -*-

import io
import os
import re
import sys
import glob
import json
import datetime

from logger import logger
import fhirclass
import fhirunittest
import fhirrenderer

# allow to skip some profiles by matching against their url (used while WiP)
skip_because_unsupported = [
    r'SimpleQuantity',
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
        self.profiles = {}              # profile-name: FHIRStructureDefinition()
        self.unit_tests = None          # FHIRUnitTestCollection()
        
        self.prepare()
        self.read_profiles()
        self.finalize()
    
    def prepare(self):
        """ Run actions before starting to parse profiles.
        """
        self.handle_manual_profiles()
    
    
    # MARK: Handling Profiles
    
    def read_profiles(self):
        """ Find all (JSON) profiles and instantiate into FHIRStructureDefinition.
        """
        resources = []
        for filename in ['profiles-types.json', 'profiles-resources.json']: #, 'profiles-others.json']:
            filepath = os.path.join(self.directory, filename)
            with io.open(filepath, encoding='utf-8') as handle:
                parsed = json.load(handle)
                assert parsed is not None
                assert 'resourceType' in parsed
                assert 'Bundle' == parsed['resourceType']
                assert 'entry' in parsed
                
                # find resources in entries
                for entry in parsed['entry']:
                    resource = entry.get('resource')
                    if resource is not None:
                        assert 'resourceType' in resource
                        if 'StructureDefinition' == resource['resourceType']:
                            resources.append(resource)
                    else:
                        logging.warning('There is no resource in this entry: {}'
                            .format(entry))
        
        # create profile instances
        for resource in resources:
            profile = FHIRStructureDefinition(self, resource)
            for pattern in skip_because_unsupported:
                if re.search(pattern, profile.url) is not None:
                    logger.info('Skipping "{}"'.format(resource['url']))
                    profile = None
                    break
            
            if profile is not None and self.found_profile(profile):
                profile.process_profile()
                    
    
    def found_profile(self, profile):
        if not profile or not profile.name:
            raise Exception("No name for profile {}".format(profile))
        if profile.name.lower() in self.profiles:
            logger.warning('Already have profile "{}", discarding'.format(profile.name))
            return False
        
        self.profiles[profile.name.lower()] = profile
        return True
    
    def handle_manual_profiles(self):
        """ Creates in-memory representations for all our manually defined
        profiles.
        """
        for filepath, module, contains in self.settings.manual_profiles:
            for contained in contains:
                profile = FHIRStructureDefinition(self, None)
                profile.is_manual = True
                
                prof_dict = {
                    'name': contained,
                    'differential': {
                        'element': [{'path': contained}]
                    }
                }
                
                profile.structure = FHIRStructureDefinitionStructure(profile, prof_dict)
                if self.found_profile(profile):
                    profile.process_profile()
    
    def finalize(self):
        """ Should be called after all profiles have been parsed and allows
        to perform additional actions, like looking up class implementations
        from different profiles.
        """
        for key, prof in self.profiles.items():
            prof.finalize()
    
    
    # MARK: Naming Utilities
    
    def as_module_name(self, name):
        return name.lower() if name and self.settings.resource_modules_lowercase else name
    
    def as_class_name(self, classname):
        if not classname or 0 == len(classname):
            return None
        if classname in self.settings.classmap:
            return self.settings.classmap[classname]
        return classname[:1].upper() + classname[1:]
    
    def mapped_name_for_type(self, type_name):
        return type_name
    
    def class_name_for_type(self, type_name):
        mappedname = self.mapped_name_for_type(type_name)
        return self.as_class_name(mappedname)
    
    def class_name_for_type_if_property(self, type_name):
        classname = self.class_name_for_type(type_name)
        if not classname:
            return None
        return self.settings.replacemap.get(classname, classname)
    
    def mapped_name_for_profile(self, profile_name):
        if not profile_name:
            return None
        type_name = profile_name.split('/')[-1]     # may be the full Profile URI, like http://hl7.org/fhir/Profile/MyProfile
        return self.mapped_name_for_type(type_name)
    
    def class_name_for_profile(self, profile_name):
        mappedname = self.mapped_name_for_profile(profile_name)
        return self.as_class_name(mappedname)
    
    def class_name_is_native(self, class_name):
        return class_name in self.settings.natives
    
    def safe_property_name(self, prop_name):
        return self.settings.reservedmap.get(prop_name, prop_name)
    
    def json_class_for_class_name(self, class_name):
        return self.settings.jsonmap.get(class_name, self.settings.jsonmap_default)
    
    @property
    def star_expand_types(self):
        return self.settings.starexpandtypes
    
    
    # MARK: Unit Tests
    
    def parse_unit_tests(self):
        controller = fhirunittest.FHIRUnitTestController(self)
        controller.find_and_parse_tests(self.directory)
        self.unit_tests = controller.collections
    
    
    # MARK: Writing Data
    
    def writable_profiles(self):
        profiles = []
        for key, profile in self.profiles.items():
            if not profile.is_manual:
                profiles.append(profile)
        return profiles
    
    def write(self):
        if self.settings.write_resources:
            renderer = fhirrenderer.FHIRStructureDefinitionRenderer(self, self.settings)
            renderer.copy_files()
            renderer.render()
        
        if self.settings.write_factory:
            renderer = fhirrenderer.FHIRFactoryRenderer(self, self.settings)
            renderer.render()
        
        if self.settings.write_unittests:
            self.parse_unit_tests()
            renderer = fhirrenderer.FHIRUnitTestRenderer(self, self.settings)
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


class FHIRStructureDefinition(object):
    """ One FHIR profile.
    """
    
    def __init__(self, spec, profile):
        self.is_manual = False
        self.spec = spec
        self.url = None
        self.targetname = None
        self.structure = None
        self.elements = None
        self.main_element = None
        self._class_map = {}
        self.classes = []
        self._did_finalize = False
        
        if profile is not None:
            self.parse_profile(profile)
    
    @property
    def name(self):
        return self.structure.name if self.structure is not None else None
    
    def read_profile(self, filepath):
        """ Read the JSON definition of a profile from disk and parse.
        
        Not currently used.
        """
        profile = None
        with io.open(filepath, 'r', encoding='utf-8') as handle:
            profile = json.load(handle)
        self.parse_profile(profile)
    
    def parse_profile(self, profile):
        """ Parse a JSON profile into a structure.
        """
        assert profile
        assert 'StructureDefinition' == profile['resourceType']
        
        # parse structure
        self.url = profile.get('url')
        logger.info('Parsing profile "{}"'.format(profile.get('name')))
        self.structure = FHIRStructureDefinitionStructure(self, profile)
    
    def process_profile(self):
        """ Extract all elements and create classes.
        """
        struct = self.structure.differential# or self.structure.snapshot
        if struct is not None:
            mapped = {}
            self.elements = []
            for elem_dict in struct:
                element = FHIRStructureDefinitionElement(self, elem_dict, self.main_element is None)
                self.elements.append(element)
                mapped[element.path] = element
                
                # establish hierarchy (may move to extra loop in case elements are no longer in order)
                if element.is_main_profile_element:
                    self.main_element = element
                parent = mapped.get(element.parent_name)
                if parent:
                    parent.add_child(element)
            
            # resolve element dependencies
            for element in self.elements:
                element.resolve_dependencies()
        
        # create classes and class properties
        if self.main_element is not None:
            snap_class, subs = self.main_element.create_class()
            if snap_class is None:
                raise Exception('The main element for "{}" did not create a class'
                    .format(self.url))
            
            self.found_class(snap_class)
            for sub in subs:
                self.found_class(sub)
            self.targetname = snap_class.name
    
    def element_with_name(self, name):
        if self.elements is not None:
            for element in self.elements:
                if element.definition.name == name:
                    return element
        return None
    
    
    # MARK: Class Handling
    
    def found_class(self, klass):
        self.classes.append(klass)
    
    def needed_external_classes(self):
        """ Returns a unique list of class items that are needed for any of the
        receiver's classes' properties and are not defined in this profile.
        
        :raises: Will raise if called before `finalize` has been called.
        """
        if not self._did_finalize:
            raise Exception('Cannot use `needed_external_classes` before finalizing')
        
        internal = set([c.name for c in self.classes])
        needed = set()
        needs = []
        
        for klass in self.classes:
            # are there superclasses that we need to import?
            sup_cls = klass.superclass
            if sup_cls is not None and sup_cls.name not in internal and sup_cls.name not in needed:
                needed.add(sup_cls.name)
                needs.append(sup_cls)
            
            # look at all properties' classes and assign their modules
            for prop in klass.properties:
                prop_cls_name = prop.class_name
                if prop_cls_name not in internal and not self.spec.class_name_is_native(prop_cls_name):
                    prop_cls = fhirclass.FHIRClass.with_name(prop_cls_name)
                    if prop_cls is None:
                        raise Exception('There is no class "{}" for property "{}" on "{}" in {}'.format(prop_cls_name, prop.name, klass.name, self.name))
                    else:
                        prop.module_name = prop_cls.module
                        if not prop_cls_name in needed:
                            needed.add(prop_cls_name)
                            needs.append(prop_cls)
        
        return sorted(needs, key=lambda n: n.module or n.name)
    
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
        
        # assign all super-classes as objects
        for cls in self.classes:
            if cls.superclass is None:
                super_cls = fhirclass.FHIRClass.with_name(cls.superclass_name)
                if super_cls is None and cls.superclass_name is not None:
                    raise Exception('There is no class implementation for class named "{}" in profile "{}"'
                        .format(cls.superclass_name, self.url))
                else:
                    cls.superclass = super_cls
        
        self._did_finalize = True


class FHIRStructureDefinitionStructure(object):
    """ The actual structure of a complete profile.
    """
    
    def __init__(self, profile, profile_dict):
        self.profile = profile
        self.name = None
        self.base = None
        self.kind = None
        self.subclass_of = None
        self.snapshot = None
        self.differential = None
        
        self.parse_from(profile_dict)
    
    def parse_from(self, json_dict):
        name = json_dict.get('name')
        if not name:
            raise Exception("Must find 'name' in profile dictionary but found nothing")
        self.name = self.profile.spec.class_name_for_profile(name) 
        self.base = json_dict.get('base')
        self.kind = json_dict.get('kind')
        if self.base:
            self.subclass_of = self.profile.spec.class_name_for_profile(self.base)
        
        # find element definitions
        if 'snapshot' in json_dict:
            self.snapshot = json_dict['snapshot'].get('element', [])
        if 'differential' in json_dict:
            self.differential = json_dict['differential'].get('element', [])


class FHIRStructureDefinitionElement(object):
    """ An element in a profile's structure.
    """
    
    def __init__(self, profile, element_dict, is_main_profile_element=False):
        assert isinstance(profile, FHIRStructureDefinition)
        self.profile = profile
        self.path = None
        self.parent = None
        self.children = None
        self.parent_name = None
        self.definition = None
        self.n_min = None
        self.n_max = None
        
        self.is_main_profile_element = is_main_profile_element
        self.represents_class = False
        
        self._superclass_name = None
        self._did_resolve_dependencies = False
        
        if element_dict is not None:
            self.parse_from(element_dict)
        else:
            self.definition = FHIRStructureDefinitionElementDefinition(self, None)
    
    def parse_from(self, element_dict):
        self.path = element_dict['path']
        parts = self.path.split('.')
        self.parent_name = '.'.join(parts[:-1]) if len(parts) > 0 else None
        prop_name = parts[-1]
        if '-' in prop_name:
            prop_name = ''.join([n[:1].upper() + n[1:] for n in prop_name.split('-')])
        
        self.definition = FHIRStructureDefinitionElementDefinition(self, element_dict)
        self.definition.prop_name = prop_name
        
        self.n_min = element_dict.get('min')
        self.n_max = element_dict.get('max')
    
    
    def resolve_dependencies(self):
        if self.is_main_profile_element:
            self.represents_class = True
        if not self.represents_class and self.children is not None and len(self.children) > 0:
            self.represents_class = True
        
        # resolve name reference
        if self.definition.name_reference:
            resolved = self.profile.element_with_name(self.definition.name_reference)
            if resolved is None:
                raise Exception('Cannot resolve nameReference "{}" in "{}"'
                    .format(self.definition.name_reference, self.profile.url))
            self.definition.update_from_reference(resolved.definition)
        
        self._did_resolve_dependencies = True
    
    
    # MARK: Hierarchy
    
    def add_child(self, element):
        element.parent = self
        if self.children is None:
            self.children = [element]
        else:
            self.children.append(element)
    
    def create_class(self, module=None):
        """ Creates a FHIRClass instance from the receiver, returning the
        created class as the first and all inline defined subclasses as the
        second item in the tuple.
        """
        assert self._did_resolve_dependencies
        if not self.represents_class:
            return None, None
        
        class_name = self.name_if_class()
        subs = []
        cls, did_create = fhirclass.FHIRClass.for_element(self)
        if did_create:
            logger.debug('Created class "{}"'.format(cls.name))
            if module is None and self.is_main_profile_element:
                module = self.profile.spec.as_module_name(cls.name)
            cls.module = module
        
        # child classes
        if self.children is not None:
            for child in self.children:
                properties = child.as_properties()
                if properties is not None:    
                    
                    # collect subclasses
                    sub, subsubs = child.create_class(module)
                    if sub is not None:
                        subs.append(sub)
                    if subsubs is not None:
                        subs.extend(subsubs)
                    
                    # add properties to class
                    if did_create:
                        for prop in properties:
                            cls.add_property(prop)
        
        return cls, subs
    
    def as_properties(self):
        """ If the element describes a *class property*, returns a list of
        FHIRClassProperty instances, None otherwise.
        """
        assert self._did_resolve_dependencies
        if self.is_main_profile_element or self.definition is None:
            return None
        
        if self.definition.slicing:
            logger.debug('Omitting property "{}" for slicing'.format(self.definition.prop_name))
            return None
        
        # this must be a property
        if self.parent is None:
            raise Exception('Element reports as property but has no parent: "{}"'
                .format(self.path))
        
        # create a list of FHIRClassProperty instances (usually with only 1 item)
        if len(self.definition.types) > 0:
            props = []
            for type_obj in self.definition.types:
                
                # an inline class
                if 'BackboneElement' == type_obj.code or 'Element' == type_obj.code:        # data types don't use "BackboneElement"
                    props.append(fhirclass.FHIRClassProperty(self, type_obj, self.name_if_class()))
                    # TODO: look at http://hl7.org/fhir/StructureDefinition/structuredefinition-explicit-type-name ?
                
                # the wildcard type: expand to all possible types, as defined in our mapping
                elif '*' == type_obj.code:
                    for exp_type in self.profile.spec.star_expand_types:
                        props.append(fhirclass.FHIRClassProperty(self, type_obj, exp_type))
                else:
                    props.append(fhirclass.FHIRClassProperty(self, type_obj))
            return props
        
        # no `type` definition in the element: it's a property with an inline class definition
        type_obj = FHIRElementType()
        return [fhirclass.FHIRClassProperty(self, type_obj, self.name_if_class())]
    
    
    # MARK: Name Utils
    
    def name_of_resource(self):
        assert self._did_resolve_dependencies
        if not self.is_main_profile_element:
            return self.name_if_class()
        return self.profile.spec.mapped_name_for_type(self.definition.name or self.path)
    
    def name_if_class(self):
        return self.definition.name_if_class()
    
    @property
    def superclass_name(self):
        """ Determine the superclass for the element (used for class elements).
        """
        if self._superclass_name is None:
            tps = self.definition.types
            if len(tps) > 1:
                raise Exception('Have more than one type to determine superclass in "{}": "{}"'
                    .format(self.path, tps))
            type_code = None
            
            if self.is_main_profile_element and self.profile.structure.subclass_of is not None:
                type_code = self.profile.structure.subclass_of
            elif len(tps) > 0:
                type_code = tps[0].code
            elif self.profile.structure.kind:
                type_code = self.profile.spec.settings.default_base.get(self.profile.structure.kind)
            self._superclass_name = self.profile.spec.class_name_for_type(type_code)
        
        return self._superclass_name


class FHIRStructureDefinitionElementDefinition(object):
    """ The definition of a FHIR element.
    """
    
    def __init__(self, element, definition_dict):
        self.element = element
        self.types = []
        self.name = None
        self.prop_name = None
        self.name_reference = None
        self.short = None
        self.formal = None
        self.comment = None
        self.constraint = None
        self.mapping = None
        self.slicing = None
        self.representation = None
        # TODO: extract "defaultValue[x]", "fixed[x]", "pattern[x]"
        # TODO: handle  "slicing"
        
        if definition_dict is not None:
            self.parse_from(definition_dict)
    
    def parse_from(self, definition_dict):
        self.types = []
        for type_dict in definition_dict.get('type', []):
            self.types.append(FHIRElementType(type_dict))
        
        self.name = definition_dict.get('name')
        self.name_reference = definition_dict.get('nameReference')
        
        self.short = definition_dict.get('short')
        self.formal = definition_dict.get('definition')
        if self.formal and self.short == self.formal[:-1]:     # formal adds a trailing period
            self.formal = None
        self.comment = definition_dict.get('comments')
        
        if 'constraint' in definition_dict:
            self.constraint = FHIRElementConstraint(definition_dict['constraint'])
        if 'mapping' in definition_dict:
            self.mapping = FHIRElementMapping(definition_dict['mapping'])
        if 'slicing' in definition_dict:
            self.slicing = definition_dict['slicing']
        self.representation = definition_dict.get('representation')
    
    def update_from_reference(self, reference_definition):
        self.element = reference_definition.element
        self.types = reference_definition.types
        self.name = reference_definition.name
        self.constraint = reference_definition.constraint
        self.mapping = reference_definition.mapping
        self.slicing = reference_definition.slicing
        self.representation = reference_definition.representation
    
    def name_if_class(self):
        """ Determines the class-name that the element would have if it was
        defining a class. This means it uses "name", if present, and the last
        "path" component otherwise.
        """
        with_name = self.name or self.prop_name
        classname = self.element.profile.spec.class_name_for_type(with_name)
        if self.element.parent is not None:
            classname = self.element.parent.name_if_class() + classname
        return classname


class FHIRElementType(object):
    """ Representing a type of an element.
    """
    
    def __init__(self, type_dict=None):
        self.code = None
        self.profile = None
        
        if type_dict is not None:
            self.parse_from(type_dict)
    
    def parse_from(self, type_dict):
        self.code = type_dict.get('code')
        if self.code is not None and not _is_string(self.code):
            raise Exception("Expecting a string for 'code' definition of an element type, got {} as {}"
                .format(self.code, type(self.code)))
        self.profiles = type_dict.get('profile')
        if self.profiles is not None and \
            (not isinstance(self.profiles, list) or 1 != len(self.profiles)):
            raise Exception("Expecting a list of 1 for 'profile' definition of an element type, got {} in {}"
                .format(self.profiles, type_dict))
        self.profile = self.profiles[0] if self.profiles is not None else None


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


def _is_string(element):
    isstr = isinstance(element, str)
    if not isstr and sys.version_info[0] < 3:       # Python 2.x has 'str' and 'unicode'
        isstr = isinstance(element, basestring)
    return isstr

