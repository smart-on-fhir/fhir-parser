#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  Facilitate working with dates.

class FHIRDate(object):
    """ Facilitate working with dates.
    """
    
    def __init__(self, jsondict=None):
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
    
