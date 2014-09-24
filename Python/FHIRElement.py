#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  Base class for all FHIR elements.


class FHIRElement(object):
    """ Base class for all FHIR elements.
    """
    
    def __init__(self, jsondict=None):
        if jsondict is not None:
            self.update_with_json(jsondict)
    
    def update_with_json(self, jsondict):
        """ Update the receiver with data in a JSON dictionary.
        """
        pass
    
    @classmethod
    def with_json(cls, jsonobj):
        """ Initialize an element from a JSON dictionary or array.
        """
        if dict == type(jsonobj):
            return cls(jsonobj)
        
        arr = []
        for jsondict in jsonobj:
            arr.append(cls(jsondict))
        return arr
    
    
    # Mark: Resource References
    
    def _resolve_reference(self, name):
        pass
    
    def _resolve_references(self, name):
        pass
    
    def _did_set_reference(self, newValue, name):
        pass
    
    def _did_set_references(self, newValue, name):
        pass
    
