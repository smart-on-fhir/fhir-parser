# Mappings for the FHIR class generator

# Which class names to map to resources and elements
classmap = {
    'Element': 'FHIRElement',
    'Structure': 'FHIRElement',
    'Resource': 'FHIRResource',
    'DomainResource': 'FHIRResource',
    'Any': 'FHIRResource',
    
    'boolean': 'Bool',
    'integer': 'Int',
    'date': 'NSDate',
    'dateTime': 'NSDate',
    'instant': 'NSDate',
    'time': 'NSDate',
    'decimal': 'NSDecimalNumber',
    
    'string': 'String',
    'id': 'String',
    'code': 'String',       # for now we're not generating enums for these
    'uri': 'NSURL',
    'oid': 'String',
    'uuid': 'String',
    'xhtml': 'String',
    'base64Binary': 'Base64Binary',
}

# Some properties (in Conformance, Profile and Questionnaire currently) can be
# any (value) type and have the `value[x]` form - how to substitute is defined
# here
starexpandtypes = {
    'integer',
    'decimal',
    'dateTime',
    'date',
    'instant',
    'time',
    'string',
    'uri',
    'boolean',
    'code',
    'base64Binary',
    
    'Coding',
    'CodeableConcept',
    'Attachment',
    'Identifier',
    'Quantity',
    'Range',
    'Period',
    'Ratio',
    'HumanName',
    'Address',
    'ContactPoint',
    'Timing',
    'Reference',
}

# Which class names are native to the lannguage
natives = ['Bool', 'Int', 'String', 'Base64Binary', 'NSNumber', 'NSDecimalNumber', 'NSDate', 'NSURL']

# Which classes are to be expected from JSON decoding
jsonmap = {
    'FHIRElement': 'NSDictionary',
    'FHIRResource': 'NSDictionary',
    
    'Int': 'Int',
    'Bool': 'Bool',
    'Double': 'NSNumber',
    
    'String': 'String',
    'NSDate': 'String',
    'NSDecimalNumber': 'NSNumber',
    'NSURL': 'String',
    'Base64Binary': 'String',
}
jsonmap_default = 'NSDictionary'

# Properties that need to be renamed because of language keyword conflicts
reservedmap = {
    'class': 'klass',
    'import': 'importFrom',
    'protocol': 'protokol',
    'extension': 'fhirExtension',
    'operator': 'operatr',
}
