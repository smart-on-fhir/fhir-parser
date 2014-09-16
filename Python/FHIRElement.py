#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  Base class for all FHIR elements.


class FHIRElement(object):
    """ Base class for all FHIR elements.
    """
    
    def __init__(self, jsondict=None):
        if jsondict is not None:
            self.updateWithJSON(jsondict)
    
    def updateWithJSON(self, jsondict):
        """ Update the receiver with data in a JSON dictionary.
        """
        pass
    
    @classmethod
    def withJSON(cls, jsonobj):
        """ Initialize an element from a JSON dictionary or array.
        """
        if dict == type(jsonobj):
            return cls(jsonobj)
        
        arr = []
        for jsondict in jsonobj:
            arr.append(cls(jsondict))
        return arr
    
    
    # Mark: Resource References
    
    def _resolveReference(self, name):
        pass
    
    def _resolveReferences(self, name):
        pass
    
    def _didSetReference(self, newValue, name):
        pass
    
    def _didSetReferences(self, newValue, name):
        pass
    
