#!/usr/bin/env python
# -*- coding: utf-8 -*-

import io
import os
import glob
import json
import logging
import datetime

import fhirclass
import fhirunittest
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
                element.represents_class = True
                klass = fhirclass.FHIRClass.for_element(element)
    
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
        if not classname or len(classname) < 2:
            raise Exception('Class names should at least be 2 chars long, have "{}"'.format(classname))
        mapped = self.settings.classmap.get(classname, classname)
        uppercased = mapped[:1].upper() + mapped[1:]
        return uppercased
    
    def class_name_for_type(self, type_name, main_resource=False):
        if type_name is None:
            if main_resource:
                type_name = self.settings.resource_default_base
            else:
                type_name = self.settings.contained_default_base
        return self.as_class_name(type_name)
    
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
    
    
    # MARK: Unit Tests
    
    def parse_unit_tests(self):
        controller = fhirunittest.FHIRUnitTestController(self, self.settings)
        controller.find_and_parse_tests(self.directory)
        self.unit_tests = controller.collections
    
    
    # MARK: Writing Data
    
    def write(self):
        if self.settings.write_resources:
            renderer = fhirrenderer.FHIRProfileRenderer(self, self.settings)
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


class FHIRProfile(object):
    """ One FHIR profile.
    """
    
    def __init__(self, spec, filepath):
        self.spec = spec
        self.targetname = None
        self.structure = None
        self._element_map = None
        self.snapshot_main = None
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
        
        # extract all snapshot elements
        if self.structure.snapshot is not None:
            self._element_map = {}
            for elem_dict in self.structure.snapshot:
                element = FHIRProfileElement(self, elem_dict)
                self._element_map[element.path] = element
                
                # establish hierarchy (may move to extra loop in case elements are no longer in order)
                if self.snapshot_main is None:
                    self.snapshot_main = element
                parent = self._element_map.get(element.parent_name)
                if parent:
                    parent.add_child(element)
        
        # create classes and class properties
        snap_class = None
        if self.snapshot_main is not None:
            snap_class, subs = self.snapshot_main.create_class()
            if snap_class is None:
                raise Exception('The main snapshot element did not create a class')
            
            self.found_class(snap_class)
            for sub in subs:
                self.found_class(sub)
            self.targetname = snap_class.name
    
    
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
                    prop_cls = fhirclass.FHIRClass.with_name(prop_cls_name)
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
                super_cls = fhirclass.FHIRClass.with_name(cls.superclass_name)
                if super_cls is None:
                    # TODO: turn into exception once we have all basic types and can parse all special cases (like "#class")
                    logging.error('There is no class implementation for class named "{}" in profile "{}"'
                        .format(cls.superclass_name, self.name))
                else:
                    cls.superclass = super_cls
            
            for prop in cls.properties:
                if prop.reference_to_profile is not None:
                    ref_cls = fhirclass.FHIRClass.with_name(prop.reference_to_name)
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
        self.snapshot = None
        
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
        if 'snapshot' in json_dict:
            self.snapshot = json_dict['snapshot'].get('element', [])


class FHIRProfileElement(object):
    """ An element in a profile's structure.
    """
    
    # properties with these names will be skipped as we implement them in our base classes
    skip_properties = [
        'extension',
        'modifierExtension',
        'meta',
        'language',
        'contained',
    ]
    
    def __init__(self, profile, element_dict):
        assert isinstance(profile, FHIRProfile)
        self.profile = profile
        self.path = None
        self.prop_name = None
        self.parent = None
        self.children = None
        self.parent_name = None
        self.definition = None
        self.is_main_profile_element = False
        self.is_resource = False
        self.represents_class = False
        
        self._superclass_name = None
        
        if element_dict is not None:
            self.parse_from(element_dict)
        else:
            self.definition = FHIRElementDefinition(self, None)
    
    def parse_from(self, element_dict):
        self.path = element_dict['path']
        if self.path == self.profile.structure.type:
            self.represents_class = True
            self.is_main_profile_element = True
            if not self.profile.structure.base or '/Element' != self.profile.structure.base[-8:]:
                self.is_resource = True
        
        self.definition = FHIRElementDefinition(self, element_dict)
        
        parts = self.path.split('.')
        self.parent_name = '.'.join(parts[:-1]) if len(parts) > 0 else None
        self.prop_name = parts[-1]
        if '-' in self.prop_name:
            self.prop_name = ''.join([n[:1].upper() + n[1:] for n in self.prop_name.split('-')])
    
    def add_child(self, element):
        element.parent = self
        if self.children is None:
            self.children = [element]
            self.represents_class = True
        else:
            self.children.append(element)
    
    def create_class(self):
        """ Creates a FHIRClass instance from the receiver, returning the
        created class as the first and all inline defined subclasses as the
        second item in the tuple.
        """
        if not self.represents_class:
            return None, None
        
        class_name = self.name_if_class()
        subs = []
        cls = fhirclass.FHIRClass.for_element(self)
        for child in self.children:
            properties = child.as_properties()
            if properties is not None:    
                
                # collect subclasses
                sub, subsubs = child.create_class()
                if sub is not None:
                    subs.append(sub)
                if subsubs is not None:
                    subs.extend(subsubs)
                
                # add properties to class
                for prop in properties:
                    cls.add_property(prop)
        
        return cls, subs
    
    def as_properties(self):
        """ If the element describes a *class property*, returns a list of
        FHIRClassProperty instances, None otherwise.
        """
        if self.prop_name in self.skip_properties:
            return None
        
        if self.is_main_profile_element or self.definition is None:
            return None
        
        if self.definition.representation:
            logging.debug('Omitting property "{}" for representation {}'.format(self.prop_name, self.definition.representation))
            return None
        
        # this must be a property
        if self.parent is None:
            raise Exception('Element reports as property but has no parent: "{}"'
                .format(self.path))
        
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
        
        # no `type` definition in the element: it's a property with an inline class definition
        type_obj = FHIRElementType(self.definition, None)
        return [fhirclass.FHIRClassProperty(self.name_if_class(), type_obj)]
    
    
    # MARK: Name Utils
    
    def name_of_resource(self):
        if self.is_resource:
            return self.profile.spec.class_name_for_type(self.prop_name)
        return None
    
    def name_if_class(self):
        """ Determines the class-name that the element would have if it was
        defining a class. This means it uses "name", if present, and the last
        "path" component otherwise.
        """
        with_name = self.definition.name if self.definition.name else self.prop_name
        classname = self.profile.spec.class_name_for_type(with_name)
        if self.parent is not None:
            classname = self.parent.name_if_class() + classname
        return classname
    
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
                # print(self.path, 'SUB', self.profile.structure.subclass_of)
                type_code = self.profile.structure.subclass_of
            elif len(tps) > 0:
                # print(self.path, 'TYP', tps[0].code)
                type_code = tps[0].code
            # else:   # type stays None, which will apply the default class name
                # print(self.path, 'ELS', self.is_main_profile_element, self.is_resource, self.profile.spec.class_name_for_type(type_code, self.is_main_profile_element))
            self._superclass_name = self.profile.spec.class_name_for_type(type_code, self.is_main_profile_element)
        
        return self._superclass_name


class FHIRElementDefinition(object):
    """ The definition of a FHIR element.
    """
    
    def __init__(self, element, definition_dict):
        self.element = element
        self.types = []
        self.name = None
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
        self.name = definition_dict.get('name')
        
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


