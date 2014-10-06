#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  Base class for FHIR resources.

from FHIRElement import FHIRElement
from FHIRSearch import FHIRSearch
from FHIRSearchElement import FHIRSearchElement


class FHIRResource(FHIRElement):
    """ Extends the FHIRElement base class with server talking capabilities.
    """
    resource_name = 'Resource'
    
    def __init__(self, jsondict=None):
        self._remote_id = None
        self._server = None
        super(FHIRResource, self).__init__(jsondict)
    
    @classmethod
    def read(cls, rem_id, server):
        """ Read the resource with the given id from the given server. The
        passed-in server instance must support a `request_json()` method call,
        taking a relative path as first (and only mandatory) argument.
        
        :param str rem_id: The id of the resource on the remote server
        :param FHIRServer server: An instance of a FHIR server or compatible class
        :returns: An instance of the receiver class
        """
        assert rem_id and server
        path = '{}/{}'.format(cls.resource_name, rem_id)
        ret = server.request_json(path)
        
        instance = cls(jsondict=ret)
        instance._remote_id = rem_id
        instance._server = server
        
        return instance
    
    
    # MARK: search
    
    def search(self, struct=None):
        """ Search can be started in two ways:
        
          - via a dictionary containing a search construct
          - by chaining FHIRSearchElement instances
        
        Calling this method with a search struct will return a `FHIRSearch`
        object representing the search struct. Not supplying a search struct
        will return a `FHIRSearchElement` instance which will accept subsequent
        search elements and create a chain.
        
        :param dict struct: An optional search structure
        :returns: A FHIRSearch or FHIRSearchElement instance
        """
        if struct is None and self._remote_id is not None:
            p = FHIRSearchElement('_id')        # TODO: currently the subject of the first search element is ignored, make this work
            p.reference = self._remote_id
            p.resource_type = self.__class__
            return p
        return self.__class__.where(struct)
    
    @classmethod
    def where(cls, struct=None):
        """ Search can be started in two ways:
        
          - via a dictionary containing a search construct
          - by chaining FHIRSearchElement instances
        
        Calling this method with a search struct will return a `FHIRSearch`
        object representing the search struct. Not supplying a search struct
        will return a `FHIRSearchElement` instance which will accept subsequent
        search elements and create a chain.
        
        :param dict struct: An optional search structure
        :returns: A FHIRSearch or FHIRSearchElement instance
        """
        if struct is not None:
            return FHIRSearch(cls.resource_name, struct)
        
        p = FHIRSearchElement(None)
        p.resource_type = cls
        return p
    
