# Mappings for the FHIR class generator

# Which class names to map to resources and elements
classmap = {
    'Any': 'Resource',
    'Practitioner.role': 'PractRole',   # to avoid Practinioner.role and PractitionerRole generating the same class
    'Protocol': 'ProtocolFHIR',
    
    'boolean': 'Bool',
    'integer': 'Int',
    'positiveInt': 'UInt',
    'unsignedInt': 'UInt',
    'decimal': 'NSDecimalNumber',
    
    'string': 'FHIRString',
    'markdown': 'FHIRString',
    'id': 'FHIRString',
    'code': 'FHIRString',       # we're not generating enums for all of these
    'uri': 'URL',
    'oid': 'FHIRString',
    'uuid': 'FHIRString',
    'xhtml': 'FHIRString',
    'base64Binary': 'Base64Binary',
    'date': 'FHIRDate',
    'time': 'FHIRTime',
}

# Classes of properties to be replaced with different ones at resource rendering time
replacemap = {}

# Some properties can be any (value) type and have the `value[x]` form - how to
# substitute is defined here
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

# Which class names represent primitives in FHIR
natives = ['Bool', 'Int', 'UInt', 'FHIRString', 'Base64Binary', 'NSNumber', 'NSDecimalNumber', 'FHIRDate', 'FHIRTime', 'DateTime', 'Instant', 'URL']

# Mapping the JSON type (value) expected for every class (key)
jsonmap = {
    'Int': 'Int',
    'UInt': 'UInt',
    'Bool': 'Bool',
    'Double': 'NSNumber',
    
    'FHIRString': 'String',
    'FHIRDate': 'String',
    'FHIRTime': 'String',
    'DateTime': 'String',
    'Instant': 'String',
    'NSDecimalNumber': 'NSNumber',
    'URL': 'String',
    'Base64Binary': 'String',
}
jsonmap_default = 'FHIRJSON'

# Properties that need to be renamed because of language keyword conflicts
reservedmap = {
    'as': '`as`',
    'class': '`class`',
    'default': '`default`',
    'extension': 'extension_fhir',
    'false': '`false`',
    'for': 'for_fhir',
    'import': 'import_fhir',
    'in': '`in`',
    'protocol': 'protocol_fhir',
    'operator': 'operator_fhir',
    'repeat': 'repeat_fhir',
    'return': '`return`',
    'self': '`self`',
    'true': '`true`',
    'description': 'description_fhir',    # Reserved for `Printable` classes
}

# For enum codes where a computer just cannot generate reasonable names
enum_map = {
    '=': 'eq',
    '<': 'lt',
    '<=': 'lte',
    '>': 'gt',
    '>=': 'gte',
    '*': 'max',
}

enum_namemap = {
    'http://hl7.org/fhir/contracttermsubtypecodes': 'ContractTermSubtypeCodes',
    'http://hl7.org/fhir/coverage-exception': 'CoverageExceptionCodes',
    'http://hl7.org/fhir/resource-type-link': 'ResourceTypeLink',
}

