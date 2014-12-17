#!/usr/bin/env python
# -*- coding: utf-8 -*-

import io
import sys
import glob
import json
import os.path
import logging


class FHIRUnitTestController(object):
    """ Can create unit tests from example files.
    """
    
    def __init__(self, spec, settings):
        self.spec = spec
        self.settings = settings
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
                coll = FHIRUnitTestCollection(test.klass, test)
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
        klass = self.spec.class_announced_as(classname)
        if klass is None:
            logging.error('There is no class for "{}"'.format(classname))
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
    """ Represents a FHIR unit test collection, meaning unit tests pertaining to
    a certain data model to be run against local sample files.
    """
    def __init__(self, klass, test):
        self.klass = klass
        self.tests = []
        self.add_test(test)
    
    def add_test(self, test):
        if test is not None:
            self.tests.append(test)


class FHIRUnitTest(object):
    """ Unit tests to be run against one data model class.
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
        """ Expand into a list of FHIRUnitTestCase instances.
        """
        tests = []
        for key, val in self.content.items():
            if 'resourceType' == key:
                continue
            
            prop = self.klass.property_for(key)
            # TODO: some "subclasses" like Age are empty because all their definitons are in their parent (Quantity). This
            # means that later on, the property lookup fails to find the properties for "Age", so fix this please.
            if prop is None:
                path = "{}.{}".format(self.prefix, key) if self.prefix else key
                logging.warning('Unknown property "{}" in unit test on {} in {}'
                    .format(path, self.klass.name, self.filepath))
            else:
                propclass = self.controller.spec.class_announced_as(prop.class_name)
                if propclass is None:
                    path = "{}.{}".format(self.prefix, key) if self.prefix else key
                    logging.error('There is no class "{}" for property "{}" in {}'
                        .format(prop.class_name, path, self.filepath))
                else:
                    path = self.controller.make_path(self.prefix, key)
                    
                    if list == type(val):
                        i = 0
                        for ival in val:
                            idxpath = self.controller.settings.unittest_format_path_index.format(path, i)
                            item = FHIRUnitTestItem(self.filepath, idxpath, ival, propclass)
                            tests.extend(item.create_tests(self.controller))
                            i += 1
                            if i > 10:
                                break;      # let's assume we don't need 100s of unit tests
                    else:
                        keypath = self.controller.settings.unittest_format_path_prepare.format(path)
                        item = FHIRUnitTestItem(self.filepath, keypath, val, propclass)
                        tests.extend(item.create_tests(self.controller))
        
        self.tests = sorted(tests, key=lambda t: t.path)


class FHIRUnitTestItem(object):
    def __init__(self, filepath, path, value, klass):
        assert path
        assert value is not None
        assert klass
        self.filepath = filepath        # needed for debug logging
        self.path = path
        self.value = value
        self.klass = klass
    
    def create_tests(self, controller):
        """ Creates as many FHIRUnitTestCase instances as the item defines.
        
        :returns: A list of FHIRUnitTestCase items, never None
        """
        tests = []
        
        # property is another element, recurse
        if dict == type(self.value):
            test = FHIRUnitTest(controller, self.filepath, self.value, self.klass, self.path)
            test.expand()
            tests.extend(test.tests)
        
        # regular test case
        else:
            isstr = isinstance(self.value, str)
            if not isstr and sys.version_info[0] < 3:       # Python 2.x has 'str' and 'unicode'
                isstr = isinstance(self.value, basestring)
            
            value = self.value.replace("\n", "\\n") if isstr else self.value
            tests.append(FHIRUnitTestCase(self.path, value, self.klass))
        
        return tests


class FHIRUnitTestCase(object):
    """ One unit test case.
    """
    def __init__(self, path, value, klass):
        self.path = path
        self.value = value
        self.klass = klass
    
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
            logging.info('Parsing unit test {}'.format(os.path.basename(self.filepath)))
            utest = None
            assert os.path.exists(self.filepath)
            with io.open(self.filepath, 'r', encoding='utf-8') as handle:
                utest = json.load(handle)
            assert utest
            self._content = utest
        
        return self._content

