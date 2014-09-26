#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Create FHIR search params from NoSQL-like query structures.

try:
    from urllib import quote_plus
except Exception as e:
    from urllib.parse import quote_plus


class FHIRSearch(object):
    """ Create FHIR search params from NoSQL-like query structures.
    """
    
    def __init__(self, struct):
        if dict != type(struct):
            raise Exception("Must pass a Python dictionary, but got a {}".format(type(struct)))
        
        self.params = []
        for key, val in struct.items():
            self.params.append(FHIRSearchParam(key, val))
    
    def construct(self):
        parts = []
        if self.params is not None:
            for param in self.params:
                for expanded in param.expand():
                    parts.append(expanded.as_parameter())
        return '&'.join(parts)


class FHIRSearchParam(object):
    """ Holds one search parameter.
    """
    
    def __init__(self, name, value):
        self.name = name
        self.value = value
        self.handler = None
    
    def copy(self):
        clone = object.__new__(self.__class__)
        clone.__dict__ = self.__dict__.copy()
        return clone
    
    def expand(self):
        """ Parse the receiver's value and return a list of directly usable
        FHIRSearchParam instances.
        """
        if self.handler is None:
            self.handler = FHIRSearchParamHandler.handler_for(self.name)(None, self.value)
        self.handler.prepare()
        return self.handler.apply(self)
    
    def as_parameter(self):
        return '{}={}'.format(self.name, quote_plus(self.value, safe=',<=>'))


class FHIRSearchParamHandler(object):
    handles = None
    handlers = []
    
    @classmethod
    def announce_handler(cls, handler):
        cls.handlers.append(handler)
    
    @classmethod
    def handler_for(cls, key):
        for handler in cls.handlers:
            if handler.can_handle(key):
                return handler
        return cls
    
    @classmethod
    def can_handle(cls, key):
        if cls.handles is not None:
            return key in cls.handles
        return True         # base class handles everything else, so be sure to test it last!
    
    
    def __init__(self, key, value):
        self.key = key
        self.value = value
        self.modifier = []
        self.multiplier = []
    
    def prepare(self, parent=None):
        if dict == type(self.value):
            for key, val in self.value.items():
                handler = FHIRSearchParamHandler.handler_for(key)(key, val)
                handler.prepare(self)
        
        if parent is not None:
            parent.multiplier.append(self)
    
    def apply(self, param):
        for handler in self.modifier:
            handler.apply(param)
        
        self._apply(param)
        
        # if we have multiplier, expand sequentially
        if len(self.multiplier) > 0:
            expanded = []
            for handler in self.multiplier:
                clone = param.copy()
                expanded.extend(handler.apply(clone))
            
            return expanded
        
        # no multiplier, just return the passed-in paramater
        return [param]
    
    def _apply(self, param):
        if self.key is not None:
            param.name = '{}.{}'.format(param.name, self.key)
        if 0 == len(self.multiplier):
            param.value = self.value


class FHIRSearchParamModifierHandler(FHIRSearchParamHandler):
    modifiers = {
        '$asc': ':asc',
        '$desc': ':desc',
        '$exact': ':exact',
        '$missing': ':missing',
        '$null': ':missing',
        '$text': ':text',
    }
    handles = modifiers.keys()
    
    def _apply(self, param):
        if self.key not in self.__class__.modifiers:
            raise Exception('Unknown modifier "{}" for "{}"'.format(self.key, param.name))
        param.name += self.__class__.modifiers[self.key]
        param.value = self.value


class FHIRSearchParamOperatorHandler(FHIRSearchParamHandler):
    operators = {
        '$gt': '>',
        '$lt': '<',
        '$lte': '<=',
        '$gte': '>=',
    }
    handles = operators.keys()
    
    def _apply(self, param):
        if self.key not in self.__class__.operators:
            raise Exception('Unknown operator "{}" for "{}"'.format(self.key, parent.name))
        param.value = self.__class__.operators[self.key] + self.value


class FHIRSearchParamMultiHandler(FHIRSearchParamHandler):
    handles = ['$and', '$or']
    
    def prepare(self, parent):
        if list != type(self.value):
            raise Exception('Expecting a list argument for "{}" but got {}'.format(parent.key, self.value))
        
        handlers = []
        for val in self.value:
            if dict == type(val):
                for kkey, vval in val.items():
                    handlers.append(FHIRSearchParamHandler.handler_for(kkey)(kkey, vval))
            else:
                handlers.append(FHIRSearchParamHandler.handler_for(parent.key)(None, val))
        
        if '$and' == self.key:
            for handler in handlers:
                handler.prepare(parent)
        elif '$or' == self.key:
            ors = [h.value for h in handlers]
            handler = FHIRSearchParamHandler.handler_for(parent.key)(None, ','.join(ors))
            handler.prepare(parent)
        else:
            raise Exception('I cannot handle "{}"'.format(self.key))


class FHIRSearchParamTypeHandler(FHIRSearchParamHandler):
    handles = ['$type']
    
    def prepare(self, parent):
        parent.modifier.append(self)
    
    def _apply(self, param):
        param.name = '{}:{}'.format(param.name, self.value)
    

# announce all handlers
FHIRSearchParamHandler.announce_handler(FHIRSearchParamModifierHandler)
FHIRSearchParamHandler.announce_handler(FHIRSearchParamOperatorHandler)
FHIRSearchParamHandler.announce_handler(FHIRSearchParamMultiHandler)
FHIRSearchParamHandler.announce_handler(FHIRSearchParamTypeHandler)


if '__main__' == __name__:
    print('1 '+FHIRSearch({'name': 'Willis'}).construct())
    print('1 name=Willis')
    print('')
    print('2 '+FHIRSearch({'name': {'$exact': 'Willis'}}).construct())
    print('2 name:exact=Willis')
    print('')
    print('3 '+FHIRSearch({'name': {'$or': ['Willis', 'Wayne', 'Bruce']}}).construct())
    print('3 name=Willis,Wayne,Bruce')
    print('')
    print('4 '+FHIRSearch({'name': {'$and': ['Willis', {'$exact': 'Bruce'}]}}).construct())
    print('4 name=Willis&name:exact=Bruce')
    print('')
    print('5 '+FHIRSearch({'birthDate': {'$gt': '1950', '$lte': '1970'}}).construct())
    print('5 birthDate=>1950&birthDate=<=1970')
    print('')
    print('6 '+FHIRSearch({'subject.name': {'$exact': 'Willis'}}).construct())
    print('6 subject.name:exact=Willis')
    print('')
    print('7 '+FHIRSearch({'subject': {'$type': 'Patient', 'name': 'Willis', 'birthDate': {'$gt': '1950', '$lte': '1970'}}}).construct())
    print('7 subject:Patient.name=Willis&subject:Patient.birthDate=>1950&subject:Patient.birthDate=<=1970')
    
