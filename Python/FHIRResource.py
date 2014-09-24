#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  Base class for FHIR resources.

from FHIRElement import FHIRElement


class FHIRResource(FHIRElement):
    """ Extends the FHIRElement base class with server talking capabilities.
    """
    
    def __init__(self, jsondict=None):
    	super(self.__class__, self).__init__(jsondict)
    	self._remote_id = None
    	self._server = None
    
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
