# Mappings for the FHIR class generator

# Which class names to map to resources and elements
classmap = {
    'Any': 'Resource',
    
    'boolean': 'bool',
    'integer': 'int',
    'positiveInt': 'int',
    'unsignedInt': 'int',
    'date': 'FHIRDate',
    'dateTime': 'FHIRDate',
    'instant': 'FHIRDate',
    'time': 'FHIRDate',
    'decimal': 'float',
    
    'string': 'str',
    'markdown': 'str',
    'id': 'str',
    'code': 'str',      # for now we're not generating enums for these
    'uri': 'str',
    'oid': 'str',
    'uuid': 'str',
    'xhtml': 'str',
    'base64Binary': 'str',
}

# Classes to be replaced with different ones at resource rendering time
replacemap = {
    'Reference': 'FHIRReference',     # `FHIRReference` adds dereferencing capabilities
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
    'Signature',
    'Reference',
}

# Which class names are native to the language (or can be treated this way)
natives = ['bool', 'int', 'float', 'str', 'dict']

# Which classes are to be expected from JSON decoding
jsonmap = {
    'str': 'str',
    'int': 'int',
    'bool': 'bool',
    'float': 'float',
    
    'FHIRDate': 'str',
}
jsonmap_default = 'dict'

# Properties that need to be renamed because of language keyword conflicts
reservedmap = {
    'for': 'for_fhir',
    'class': 'class_fhir',
    'import': 'import_fhir',
    'global': 'global_fhir',
    'assert': 'assert_fhir',
    'except': 'except_fhir',
}

