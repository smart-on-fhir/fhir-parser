#!/usr/bin/env python
# -*- coding: utf-8 -*-


class FHIRClass(object):
    """ An element/resource that should become its own class.
    """
    
    def __init__(self, element):
        assert element is not None      # and must be instance of FHIRElement
        self.path = element.path
        self.name = element.name_if_class()
        self.module = element.profile.spec.as_module_name(self.name)
        self.resource_name = element.name_of_resource()
        self.superclass = None
        self.superclass_name = element.name_for_superclass()
        self.short = element.definition.short
        self.formal = element.definition.formal
        self.properties = []
    
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
                if not existing.reference_to_profile:
                    raise Exception('Already have property "{}" on "{}", which is only allowed for references'.format(prop.name, self.name))
                
                existing.reference_to_profile = 'Resource'
                return
        
        self.properties.append(prop)
        self.properties = sorted(self.properties, key=lambda x: x.name)
    
    def property_for(self, prop_name):
        for prop in self.properties:
            if prop.name == prop_name:
                return prop
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


class FHIRClassProperty(object):
    """ An element describing an instance property.
    """
    
    def __init__(self, type_name, type_obj):
        assert type_obj is not None     # and must be instance of FHIRElementType
        elem = type_obj.definition.element
        spec = elem.profile.spec
        
        self.path = elem.path
        name = elem.name
        if '[x]' in name:
            # < v0.3: "MedicationPrescription.reason[x]" can be a
            # "ResourceReference" but apparently should be called
            # "reasonResource", NOT "reasonResourceReference".
            kl = 'Resource' if 'ResourceReference' == type_name else type_name  # < v0.3
            name = name.replace('[x]', '{}{}'.format(kl[:1].upper(), kl[1:]))
        
        self.orig_name = name
        self.name = spec.safe_property_name(name)
        self.parent_name = type_obj.elements_parent_name()
        self.class_name = spec.class_name_for_type(type_name)
        self.module_name = None             # should only be set if it's an external module (think Python)
        self.json_class = spec.json_class_for_class_name(self.class_name)
        self.is_native = spec.class_name_is_native(self.class_name)
        self.is_array = True if '*' == type_obj.definition.n_max else False
        self.nonoptional = True if type_obj.definition.n_min is not None and 0 != int(type_obj.definition.n_min) else False
        self.reference_to_profile = type_obj.profile
        self.reference_to_name = spec.class_name_for_profile(self.reference_to_profile)
        self.reference_to = None
        self.short = type_obj.definition.short

