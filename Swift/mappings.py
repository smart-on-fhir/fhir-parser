# Mappings for the FHIR class generator

# Which class names to map to resources and properties
classmap = {
    'Element': 'FHIRElement',
    'Structure': 'FHIRElement',
    'Resource': 'FHIRResource',                 # < v0.3
    'ResourceReference': 'FHIRReference',       # < v0.3
    'DomainResource': 'FHIRResource',           # v0.3
    'Reference': 'FHIRReference',               # v0.3
    'Any': 'FHIRResource',
    
    'boolean': 'Bool',
    'integer': 'Int',
    'date': 'NSDate',
    'dateTime': 'NSDate',
    'instant': 'NSDate',
    'decimal': 'NSDecimalNumber',
    
    'string': 'String',
    'id': 'String',
    'oid': 'String',
    'idref': 'String',
    'uri': 'NSURL',
    'base64Binary': 'String',
    'xhtml': 'String',
    'code': 'String',       # for now we're not generating enums for these
}

# Which mapped class is a subclass of a profile (used for FHIRReference)
subclassmap = {
    'FHIRReference': 'ResourceReference',
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
    'Contact',
    'Schedule',
    'Resource',
}

# Which class names are native to the lannguage
natives = ['Bool', 'Int', 'String', 'NSNumber', 'NSDecimalNumber', 'NSDate', 'NSURL']

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
