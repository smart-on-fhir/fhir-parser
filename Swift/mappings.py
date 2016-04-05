# Mappings for the FHIR class generator

# Which class names to map to resources and elements
classmap = {
    'Any': 'Resource',
    
    'boolean': 'Bool',
    'integer': 'Int',
    'positiveInt': 'UInt',
    'unsignedInt': 'UInt',
    'decimal': 'NSDecimalNumber',
    
    'string': 'String',
    'markdown': 'String',
    'id': 'String',
    'code': 'String',       # for now we're not generating enums for these
    'uri': 'NSURL',
    'oid': 'String',
    'uuid': 'String',
    'xhtml': 'String',
    'base64Binary': 'Base64Binary',
}

# Classes to be replaced with different ones at resource rendering time
replacemap = {}

# Some properties (in Conformance, Profile and Questionnaire currently) can be
# any (value) type and have the `value[x]` form - how to substitute is defined
# here
# see http://hl7.org/fhir/2015May/datatypes.html#1.18.0.17
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
natives = ['Bool', 'Int', 'UInt', 'String', 'Base64Binary', 'NSNumber', 'NSDecimalNumber', 'Date', 'Time', 'DateTime', 'Instant', 'NSURL']

# Which classes are to be expected from JSON decoding
jsonmap = {
    'Int': 'Int',
    'UInt': 'UInt',
    'Bool': 'Bool',
    'Double': 'NSNumber',
    
    'String': 'String',
    'Date': 'String',
    'Time': 'String',
    'DateTime': 'String',
    'Instant': 'String',
    'NSDecimalNumber': 'NSNumber',
    'NSURL': 'String',
    'Base64Binary': 'String',
}
jsonmap_default = 'FHIRJSON'

# Properties that need to be renamed because of language keyword conflicts
reservedmap = {
    'for': 'for_fhir',
    'class': 'class_fhir',
    'import': 'import_fhir',
    'protocol': 'protocol_fhir',
    'extension': 'extension_fhir',
    'operator': 'operator_fhir',
    'repeat': 'repeat_fhir',
    'description': 'description_fhir',    # Reserved for `Printable` classes
}
