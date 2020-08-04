#!/usr/bin/env python
# -*- coding: utf-8 -*-

import io
import re
import sys
import glob
import json
import os.path

from logger import logger
import fhirclass


class FHIRUnitTestController(object):
    """ Can create unit tests from example files.
    """
    
    def __init__(self, spec, settings=None):
        self.spec = spec
        self.settings = settings or spec.settings
        self.files = None
        self.collections = None
    
    def find_and_parse_tests(self, directory):
        self.files = FHIRResourceFile.find_all(directory)
        
        # create tests
        tests = []
        for resource in self.files:
            test = self.unittest_for_resource(resource)
            if test is not None:
                tests.append(test)
        
        # collect per class
        collections = {}
        for test in tests:
            coll = collections.get(test.klass.name)
            if coll is None:
                coll = FHIRUnitTestCollection(test.klass)
                collections[test.klass.name] = coll
            coll.add_test(test)
        
        self.collections = [v for k,v in collections.items()]
    
    
    # MARK: Utilities
    
    def unittest_for_resource(self, resource):
        """ Returns a FHIRUnitTest instance or None for the given resource,
        depending on if the class to be tested is known.
        """
        classname = resource.content.get('resourceType')
        assert classname
        if classname in self.settings.classmap:
            classname = self.settings.classmap[classname]
        klass = fhirclass.FHIRClass.with_name(classname)
        if klass is None:
            logger.error('There is no class for "{}", cannot create unit tests'
                .format(classname))
            return None
        
        return FHIRUnitTest(self, resource.filepath, resource.content, klass)
    
    def make_path(self, prefix, key):
        """ Takes care of combining prefix and key into a path.
        """
        path = key
        if prefix:
            path = self.settings.unittest_format_path_key.format(prefix, path)
        return path


class FHIRUnitTestCollection(object):
    """ Represents a FHIR unit test collection, meaning unit tests pertaining
    to one data model class, to be run against local sample files.
    """
    def __init__(self, klass):
        self.klass = klass
        self.tests = []
    
    def add_test(self, test):
        if test is not None:
            if len(self.tests) < 10:
                self.tests.append(test)      # let's assume we don't need 100s of unit tests


class FHIRUnitTest(object):
    """ Holds on to unit tests (FHIRUnitTestItem in `tests`) that are to be run
    against one data model class (`klass`).
    """
    def __init__(self, controller, filepath, content, klass, prefix=None):
        assert content and klass
        self.controller = controller
        self.filepath = filepath
        self.filename = os.path.basename(filepath)
        self.content = content
        self.klass = klass
        self.prefix = prefix
        
        self.tests = None
        self.expand()
    
    def expand(self):
        """ Expand into a list of FHIRUnitTestItem_name instances.
        """
        tests = []
        for key, val in self.content.items():
            if 'resourceType' == key or 'fhir_comments' == key or '_' == key[:1]:
                continue
            
            prop = self.klass.property_for(key)
            if prop is None:
                path = "{}.{}".format(self.prefix, key) if self.prefix else key
                logger.warning('Unknown property "{}" in unit test on {} in {}'
                    .format(path, self.klass.name, self.filepath))
            else:
                propclass = fhirclass.FHIRClass.with_name(prop.class_name)
                if propclass is None:
                    path = "{}.{}".format(self.prefix, prop.name) if self.prefix else prop.name
                    logger.error('There is no class "{}" for property "{}" in {}'
                        .format(prop.class_name, path, self.filepath))
                else:
                    path = self.controller.make_path(self.prefix, prop.name)
                    
                    if list == type(val):
                        i = 0
                        for ival in val:
                            idxpath = self.controller.settings.unittest_format_path_index.format(path, i)
                            item = FHIRUnitTestItem(self.filepath, idxpath, ival, propclass, True, prop.enum)
                            tests.extend(item.create_tests(self.controller))
                            i += 1
                            if i >= 10:     # let's assume we don't need 100s of unit tests
                                break
                    else:
                        item = FHIRUnitTestItem(self.filepath, path, val, propclass, False, prop.enum)
                        tests.extend(item.create_tests(self.controller))
        
        self.tests = sorted(tests, key=lambda t: t.path)


class FHIRUnitTestItem(object):
    """ Represents unit tests to be performed against a single data model
    property. If the property itself is an element, will be expanded into
    more FHIRUnitTestItem that cover its own properties.
    """
    
    def __init__(self, filepath, path, value, klass, array_item, enum_item):
        assert path
        assert value is not None, (filepath, path)
        assert klass
        self.filepath = filepath        # needed for debug logging
        self.path = path
        self.value = value
        self.klass = klass
        self.array_item = array_item
        self.enum = enum_item.name if enum_item is not None else None
    
    def create_tests(self, controller):
        """ Creates as many FHIRUnitTestItem instances as the item defines, or
        just returns a list containing itself if this property is not an
        element.
        
        :returns: A list of FHIRUnitTestItem items, never None
        """
        tests = []
        
        # property is another element, recurse
        if dict == type(self.value):
            prefix = self.path
            if not self.array_item:
                prefix = controller.settings.unittest_format_path_prepare.format(prefix)
            
            test = FHIRUnitTest(controller, self.filepath, self.value, self.klass, prefix)
            tests.extend(test.tests)
        
        # regular test case; skip string tests that are longer than 200 chars
        else:
            isstr = isinstance(self.value, str)
            if not isstr and sys.version_info[0] < 3:       # Python 2.x has 'str' and 'unicode'
                isstr = isinstance(self.value, basestring)
            
            value = self.value
            if isstr:
                if len(value) > 200:
                    return tests
                elif not hasattr(value, 'isprintable'):       # Python 2.x doesn't have it
                    try:
                        value.decode('utf-8')
                    except Exception:
                        return tests
                elif not value.isprintable():
                    return tests
                
                value = self.value.replace("\n", "\\n")
            tests.append(self)
        
        return tests
    
    def __repr__(self):
        return 'Unit Test Case "{}": "{}"'.format(self.path, self.value)


class FHIRResourceFile(object):
    """ A FHIR example resource file.
    """
    @classmethod
    def find_all(cls, directory):
        """ Finds all example JSON files in the given directory.
        """
        assert os.path.isdir(directory)
        all_tests = []
        for utest in glob.glob(os.path.join(directory, '*-example*.json')):
            if 'canonical.json' not in utest:
                all_tests.append(cls(filepath=utest))
        
        return all_tests
    
    def __init__(self, filepath):
        self.filepath = filepath
        self._content = None
    
    @property
    def content(self):
        """ Process the unit test file, determining class structure
        from the given classes dict.
        
        :returns: A tuple with (top-class-name, [test-dictionaries])
        """
        if self._content is None:
            logger.info('Parsing unit test {}'.format(os.path.basename(self.filepath)))
            utest = None
            assert os.path.exists(self.filepath)
            with io.open(self.filepath, 'r', encoding='utf-8') as handle:
                utest = json.load(handle)
            assert utest
            self._content = utest
        
        return self._content

