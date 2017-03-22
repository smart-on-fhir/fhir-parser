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
        self.valuesets = {}             # system-url: FHIRValueSet()
        self.codesystems = {}           # system-url: FHIRCodeSystem()
        self.profiles = {}              # profile-name: FHIRStructureDefinition()
        self.unit_tests = None          # FHIRUnitTestCollection()
        
        self.prepare()
        self.read_profiles()
        self.finalize()
    
    def prepare(self):
        """ Run actions before starting to parse profiles.
        """
        self.read_valuesets()
        self.handle_manual_profiles()
    
    def read_bundle_resources(self, filename):
        """ Return an array of the Bundle's entry's "resource" elements.
        """
        logger.info("Reading {}".format(filename))
        filepath = os.path.join(self.directory, filename)
        with io.open(filepath, encoding='utf-8') as handle:
            parsed = json.load(handle)
            if 'resourceType' not in parsed:
                raise Exception("Expecting \"resourceType\" to be present, but is not in {}"
                    .format(filepath))
            if 'Bundle' != parsed['resourceType']:
                raise Exception("Can only process \"Bundle\" resources")
            if 'entry' not in parsed:
                raise Exception("There are no entries in the Bundle at {}"
                    .format(filepath))
            
            return [e['resource'] for e in parsed['entry']]
    
    
    # MARK: Managing ValueSets and CodeSystems
    
    def read_valuesets(self):
        resources = self.read_bundle_resources('valuesets.json')
        for resource in resources:
            if 'ValueSet' == resource['resourceType']:
                assert 'url' in resource
                self.valuesets[resource['url']] = FHIRValueSet(self, resource)
            elif 'CodeSystem' == resource['resourceType']:
                assert 'url' in resource
                self.codesystems[resource['url']] = FHIRCodeSystem(self, resource)
        logger.info("Found {} ValueSets and {} CodeSystems".format(len(self.valuesets), len(self.codesystems)))
    
    def valueset_with_uri(self, uri):
        assert uri
        return self.valuesets.get(uri)
    
    def codesystem_with_uri(self, uri):
        assert uri
        return self.codesystems.get(uri)
    
    
    # MARK: Handling Profiles
    
    def read_profiles(self):
        """ Find all (JSON) profiles and instantiate into FHIRStructureDefinition.
        """
        resources = []
        for filename in ['profiles-types.json', 'profiles-resources.json']: #, 'profiles-others.json']:
            bundle_res = self.read_bundle_resources(filename)
            for resource in bundle_res:
                if 'StructureDefinition' == resource['resourceType']:
                    resources.append(resource)
                else:
                    logger.debug('Not handling resource of type {}'
                        .format(resource['resourceType']))
        
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
            logger.debug('Already have profile "{}", discarding'.format(profile.name))
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
    
    def as_class_name(self, classname, parent_name=None):
        if not classname or 0 == len(classname):
            return None
        
        # if we have a parent, do we have a mapped class?
        pathname = '{}.{}'.format(parent_name, classname) if parent_name is not None else None
        if pathname is not None and pathname in self.settings.classmap:
            return self.settings.classmap[pathname]
        
        # is our plain class mapped?
        if classname in self.settings.classmap:
            return self.settings.classmap[classname]
        
        # CamelCase or just plain
        if self.settings.camelcase_classes:
            return classname[:1].upper() + classname[1:]
        return classname
    
    def class_name_for_type(self, type_name, parent_name=None):
        return self.as_class_name(type_name, parent_name)
    
    def class_name_for_type_if_property(self, type_name):
        classname = self.class_name_for_type(type_name)
        if not classname:
            return None
        return self.settings.replacemap.get(classname, classname)
    
    def class_name_for_profile(self, profile_name):
        if not profile_name:
            return None
        type_name = profile_name.split('/')[-1]     # may be the full Profile URI, like http://hl7.org/fhir/Profile/MyProfile
        return self.as_class_name(type_name)
    
    def class_name_is_native(self, class_name):
        return class_name in self.settings.natives
    
    def safe_property_name(self, prop_name):
        return self.settings.reservedmap.get(prop_name, prop_name)
    
    def safe_enum_name(self, enum_name, ucfirst=False):
        assert enum_name, "Must have a name"
        name = self.settings.enum_map.get(enum_name, enum_name)
        parts = re.split('\W+', name)
        if self.settings.camelcase_enums:
            name = ''.join([n[:1].upper() + n[1:] for n in parts])
            if not ucfirst and name.upper() != name:
                name = name[:1].lower() + name[1:]
        else:
            name = '_'.join(parts)
        return self.settings.reservedmap.get(name, name)
    
    def json_class_for_class_name(self, class_name):
        return self.settings.jsonmap.get(class_name, self.settings.jsonmap_default)
    
    
    # MARK: Unit Tests
    
    def parse_unit_tests(self):
        controller = fhirunittest.FHIRUnitTestController(self)
        controller.find_and_parse_tests(self.directory)
        self.unit_tests = controller.collections
    
    
    # MARK: Writing Data
    
    def writable_profiles(self):
        """ Returns a list of `FHIRStructureDefinition` instances.
        """
        profiles = []
        for key, profile in self.profiles.items():
            if not profile.is_manual:
                profiles.append(profile)
        return profiles
    
    def write(self):
        if self.settings.write_resources:
            renderer = fhirrenderer.FHIRStructureDefinitionRenderer(self, self.settings)
            renderer.render()
            
            vsrenderer = fhirrenderer.FHIRValueSetRenderer(self, self.settings)
            vsrenderer.render()
        
        if self.settings.write_factory:
            renderer = fhirrenderer.FHIRFactoryRenderer(self, self.settings)
            renderer.render()
        
        if self.settings.write_dependencies:
            renderer = fhirrenderer.FHIRDependencyRenderer(self, self.settings)
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


class FHIRValueSet(object):
    """ Holds on to ValueSets bundled with the spec.
    """
    
    def __init__(self, spec, set_dict):
        self.spec = spec
        self.definition = set_dict
        self._enum = None
    
    @property
    def enum(self):
        """ Returns FHIRCodeSystem if this valueset can be represented by one.
        """
        if self._enum is not None:
            return self._enum
        
        compose = self.definition.get('compose')
        if compose is None:
            raise Exception("Currently only composed ValueSets are supported")
        if 'exclude' in compose:
            raise Exception("Not currently supporting 'exclude' on ValueSet")
        include = compose.get('include')
        if 1 != len(include):
            logger.warn("Ignoring ValueSet with more than 1 includes ({}: {})".format(len(include), include))
            return None
        
        system = include[0].get('system')
        if system is None:
            return None
        
        # alright, this is a ValueSet with 1 include and a system, is there a CodeSystem?
        cs = self.spec.codesystem_with_uri(system)
        if cs is None or not cs.generate_enum:
            return None
        
        # do we only allow specific concepts?
        restricted_to = []
        concepts = include[0].get('concept')
        if concepts is not None:
            for concept in concepts:
                assert 'code' in concept
                restricted_to.append(concept['code'])
        
        self._enum = {
            'name': cs.name,
            'restricted_to': restricted_to if len(restricted_to) > 0 else None,
        }
        return self._enum


class FHIRCodeSystem(object):
    """ Holds on to CodeSystems bundled with the spec.
    """
    
    def __init__(self, spec, resource):
        assert 'content' in resource
        self.spec = spec
        self.definition = resource
        self.url = resource.get('url')
        if self.url in self.spec.settings.enum_namemap:
            self.name = self.spec.settings.enum_namemap[self.url]
        else:
            self.name = self.spec.safe_enum_name(resource.get('name'), ucfirst=True)
        self.codes = None
        self.generate_enum = False
        concepts = self.definition.get('concept', [])
        
        if resource.get('experimental'):
            return
        self.generate_enum = 'complete' == resource['content']
        if not self.generate_enum:
            logger.debug("Will not generate enum for CodeSystem \"{}\" whose content is {}"
                .format(self.url, resource['content']))
            return
        
        assert concepts, "Expecting at least one code for \"complete\" CodeSystem"
        if len(concepts) > 100:
            self.generate_enum = False
            logger.info("Will not generate enum for CodeSystem \"{}\" because it has > 100 ({}) concepts"
                .format(self.url, len(concepts)))
            return
        
        self.codes = self.parsed_codes(concepts)
    
    def parsed_codes(self, codes, prefix=None):
        found = []
        for c in codes:
            if re.match(r'\d', c['code'][:1]):
                self.generate_enum = False
                logger.info("Will not generate enum for CodeSystem \"{}\" because at least one concept code starts with a number"
                    .format(self.url))
                return None
            
            cd = c['code']
            name = '{}-{}'.format(prefix, cd) if prefix and not cd.startswith(prefix) else cd
            c['name'] = self.spec.safe_enum_name(cd)
            c['definition'] = c.get('definition') or c['name']
            found.append(c)
            
            # nested concepts?
            if 'concept' in c:
                fnd = self.parsed_codes(c['concept'])
                if fnd is None:
                    return None
                found.extend(fnd)
        return found


class FHIRStructureDefinition(object):
    """ One FHIR structure definition.
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
            
            # run check: if n_min > 0 and parent is in summary, must also be in summary
            for element in self.elements:
                if element.n_min is not None and element.n_min > 0:
                    if element.parent is not None and element.parent.is_summary and not element.is_summary:
                        logger.error("n_min > 0 but not summary: `{}`".format(element.path))
                        element.summary_n_min_conflict = True
        
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
    
    def element_with_id(self, ident):
        """ Returns a FHIRStructureDefinitionElementDefinition with the given
        id, if found. Used to retrieve elements defined via `contentReference`.
        """
        if self.elements is not None:
            for element in self.elements:
                if element.definition.id == ident:
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
    
    def referenced_classes(self):
        """ Returns a unique list of **external** class names that are
        referenced from at least one of the receiver's `Reference`-type
        properties.
        
        :raises: Will raise if called before `finalize` has been called.
        """
        if not self._did_finalize:
            raise Exception('Cannot use `referenced_classes` before finalizing')
        
        references = set()
        for klass in self.classes:
            for prop in klass.properties:
                if len(prop.reference_to_names) > 0:
                    references.update(prop.reference_to_names)
        
        # no need to list references to our own classes, remove them
        for klass in self.classes:
            references.discard(klass.name)
        
        return sorted(references)
    
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
        self.base = json_dict.get('baseDefinition')
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
        self.is_summary = False
        self.summary_n_min_conflict = False  # to mark conflicts, see #13215 (http://gforge.hl7.org/gf/project/fhir/tracker/?action=TrackerItemEdit&tracker_item_id=13125)
        self.valueset = None
        self.enum = None      # assigned if the element has a binding to a ValueSet that is a CodeSystem generating an enum
        
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
        self.is_summary = element_dict.get('isSummary')
    
    def resolve_dependencies(self):
        if self.is_main_profile_element:
            self.represents_class = True
        if not self.represents_class and self.children is not None and len(self.children) > 0:
            self.represents_class = True
        if self.definition is not None:
            self.definition.resolve_dependencies()
        
        self._did_resolve_dependencies = True
    
    
    # MARK: Hierarchy
    
    def add_child(self, element):
        assert isinstance(element, FHIRStructureDefinitionElement)
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
        
        # TODO: handle slicing information (not sure why these properties were
        # omitted previously)
        #if self.definition.slicing:
        #    logger.debug('Omitting property "{}" for slicing'.format(self.definition.prop_name))
        #    return None
        
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
        return self.definition.name or self.path
    
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
        self.id = None
        self.element = element
        self.types = []
        self.name = None
        self.prop_name = None
        self.content_reference = None
        self._content_referenced = None
        self.short = None
        self.formal = None
        self.comment = None
        self.binding = None
        self.constraint = None
        self.mapping = None
        self.slicing = None
        self.representation = None
        # TODO: extract "defaultValue[x]", "fixed[x]", "pattern[x]"
        # TODO: handle  "slicing"
        
        if definition_dict is not None:
            self.parse_from(definition_dict)
    
    def parse_from(self, definition_dict):
        self.id = definition_dict.get('id')
        self.types = []
        for type_dict in definition_dict.get('type', []):
            self.types.append(FHIRElementType(type_dict))
        
        self.name = definition_dict.get('name')
        self.content_reference = definition_dict.get('contentReference')
        
        self.short = definition_dict.get('short')
        self.formal = definition_dict.get('definition')
        if self.formal and self.short == self.formal[:-1]:     # formal adds a trailing period
            self.formal = None
        self.comment = definition_dict.get('comments')
        
        if 'binding' in definition_dict:
            self.binding = FHIRElementBinding(definition_dict['binding'])
        if 'constraint' in definition_dict:
            self.constraint = FHIRElementConstraint(definition_dict['constraint'])
        if 'mapping' in definition_dict:
            self.mapping = FHIRElementMapping(definition_dict['mapping'])
        if 'slicing' in definition_dict:
            self.slicing = definition_dict['slicing']
        self.representation = definition_dict.get('representation')
    
    def resolve_dependencies(self):
        # update the definition from a reference, if there is one
        if self.content_reference is not None:
            if '#' != self.content_reference[:1]:
                raise Exception("Only relative 'contentReference' element definitions are supported right now")
            elem = self.element.profile.element_with_id(self.content_reference[1:])
            if elem is None:
                raise Exception("There is no element definiton with id \"{}\", as referenced by {} in {}"
                    .format(self.content_reference, self.path, self.profile.url))
            self._content_referenced = elem.definition
        
        # resolve bindings
        if self.binding is not None and self.binding.is_required:
            uri = self.binding.reference or self.binding.uri
            if 'http://hl7.org/fhir' != uri[:19]:
                logger.debug("Ignoring foreign ValueSet \"{}\"".format(uri))
                return
            
            valueset = self.element.profile.spec.valueset_with_uri(uri)
            if valueset is None:
                logger.error("There is no ValueSet for required binding \"{}\" on {} in {}"
                    .format(uri, self.name or self.prop_name, self.element.profile.name))
            else:
                self.element.valueset = valueset
                self.element.enum = valueset.enum
    
    def name_if_class(self):
        """ Determines the class-name that the element would have if it was
        defining a class. This means it uses "name", if present, and the last
        "path" component otherwise.
        """
        if self._content_referenced is not None:
            return self._content_referenced.name_if_class()
        
        with_name = self.name or self.prop_name
        parent_name = self.element.parent.name_if_class() if self.element.parent is not None else None
        classname = self.element.profile.spec.class_name_for_type(with_name, parent_name)
        if parent_name is not None and self.element.profile.spec.settings.backbone_class_adds_parent:
            classname = parent_name + classname
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
        self.profile = type_dict.get('targetProfile')
        if self.profile is not None and not _is_string(self.profile):
            raise Exception("Expecting a string for 'targetProfile' definition of an element type, got {} as {}"
                .format(self.profile, type(self.profile)))


class FHIRElementBinding(object):
    """ The "binding" element in an element definition
    """
    def __init__(self, binding_obj):
        self.strength = binding_obj.get('strength')
        self.description = binding_obj.get('description')
        self.uri = binding_obj.get('valueSetUri')
        self.reference = binding_obj.get('valueSetReference', {}).get('reference')
        self.is_required = 'required' == self.strength


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

