#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  Subclassing FHIR's resource reference to add resolving capabilities

import ResourceReference


class FHIRReference(ResourceReference.ResourceReference):
    """ Subclassing FHIR's resource reference to add resolving capabilities.
    """
    
    def __init__(self, jsondict=None):
        self._referenced_class = None
        super(ResourceReference.ResourceReference, self).__init__(jsondict)
    
    @classmethod
    def with_json_and_class(cls, jsonobj, klass):
        """ Takes the class the reference is referencing and forwards to
        `with_json()`.
        
        :param klass: The class the reference is representing; must be a
            FHIRElement subclass!
        :returns: An instance or a list of instances created from JSON data
        """
        instance = cls.with_json(jsonobj)
        if list == type(instance):
            for inst in instance:
                inst._referenced_class = klass
        else:
            instance._referenced_class = klass
        
        return instance
    
    @property
    def resolved(self):
        """ Resolves the reference and caches the result, returning instance(s)
        of the referenced classes.
        
        :returns: An instance (or list thereof) of the resolved reference if
            dereferencing was successful, `None` otherwise
        """
        if self._referenced_class is None:
            raise Exception("Cannot resolve reference without having `_referenced_class` set")
        
        # TODO: resolve
        return None
    
