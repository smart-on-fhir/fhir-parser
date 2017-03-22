#!/usr/bin/env python
# -*- coding: utf-8 -*-

from logger import logger


class FHIRClass(object):
    """ An element/resource that should become its own class.
    """
    
    known = {}
    
    @classmethod
    def for_element(cls, element):
        """ Returns an existing class or creates one for the given element.
        Returns a tuple with the class and a bool indicating creation.
        """
        assert element.represents_class
        class_name = element.name_if_class()
        if class_name in cls.known:
            return cls.known[class_name], False
        
        klass = cls(element)
        cls.known[class_name] = klass
        return klass, True
    
    @classmethod
    def with_name(cls, class_name):
        return cls.known.get(class_name)
    
    def __init__(self, element):
        assert element.represents_class
        self.path = element.path
        self.name = element.name_if_class()
        self.module = None
        self.resource_type = element.name_of_resource()
        self.superclass = None
        self.superclass_name = element.superclass_name
        self.short = element.definition.short
        self.formal = element.definition.formal
        self.properties = []
        self.expanded_nonoptionals = {}
    
    def add_property(self, prop):
        """ Add a property to the receiver.
        
        :param FHIRClassProperty prop: A FHIRClassProperty instance
        """
        assert isinstance(prop, FHIRClassProperty)
        
        # do we already have a property with this name?
        # if we do and it's a specific reference, make it a reference to a
        # generic resource
        for existing in self.properties:
            if existing.name == prop.name:
                if 0 == len(existing.reference_to_names):
                    logger.warning('Already have property "{}" on "{}", which is only allowed for references'.format(prop.name, self.name))
                else:
                    existing.reference_to_names.extend(prop.reference_to_names)
                return
        
        self.properties.append(prop)
        self.properties = sorted(self.properties, key=lambda x: x.name)
        
        if prop.nonoptional and prop.one_of_many is not None:
            if prop.one_of_many in self.expanded_nonoptionals:
                self.expanded_nonoptionals[prop.one_of_many].append(prop)
            else:
                self.expanded_nonoptionals[prop.one_of_many] = [prop]
    
    @property
    def nonexpanded_properties(self):
        nonexpanded = []
        included = set()
        for prop in self.properties:
            if prop.one_of_many:
                if prop.one_of_many in included:
                    continue
                included.add(prop.one_of_many)
            nonexpanded.append(prop)
        return nonexpanded
    
    @property
    def nonexpanded_nonoptionals(self):
        nonexpanded = []
        included = set()
        for prop in self.properties:
            if not prop.nonoptional:
                continue
            if prop.one_of_many:
                if prop.one_of_many in included:
                    continue
                included.add(prop.one_of_many)
            nonexpanded.append(prop)
        return nonexpanded
    
    def property_for(self, prop_name):
        for prop in self.properties:
            if prop.orig_name == prop_name:
                return prop
        if self.superclass and self != self.superclass:         # Element is its own superclass
            return self.superclass.property_for(prop_name)
        return None
    
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
    
    @property
    def sorted_nonoptionals(self):
        return sorted(self.expanded_nonoptionals.items())


class FHIRClassProperty(object):
    """ An element describing an instance property.
    """
    
    def __init__(self, element, type_obj, type_name=None):
        assert element and type_obj     # and must be instances of FHIRStructureDefinitionElement and FHIRElementType
        spec = element.profile.spec
        
        self.path = element.path
        self.one_of_many = None         # assign if this property has been expanded from "property[x]"
        if not type_name:
            type_name = type_obj.code
        
        name = element.definition.prop_name
        if '[x]' in name:
            self.one_of_many = name.replace('[x]', '')
            name = name.replace('[x]', '{}{}'.format(type_name[:1].upper(), type_name[1:]))
        
        self.orig_name = name
        self.name = spec.safe_property_name(name)
        self.parent_name = element.parent_name
        self.class_name = spec.class_name_for_type_if_property(type_name)
        self.enum = element.enum if 'code' == type_name else None
        self.module_name = None             # should only be set if it's an external module (think Python)
        self.json_class = spec.json_class_for_class_name(self.class_name)
        self.is_native = False if self.enum else spec.class_name_is_native(self.class_name)
        self.is_array = True if '*' == element.n_max else False
        self.is_summary = element.is_summary
        self.is_summary_n_min_conflict = element.summary_n_min_conflict
        self.nonoptional = True if element.n_min is not None and 0 != int(element.n_min) else False
        self.reference_to_names = [spec.class_name_for_profile(type_obj.profile)] if type_obj.profile is not None else []
        self.short = element.definition.short
        self.formal = element.definition.formal
        self.representation = element.definition.representation

