# Mappings for the FHIR class generator

# Which class names to map to resources and properties
classmap = {
	'Structure': 'FHIRElement',
	'Resource': 'FHIRResource',
	
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
	'code': 'String',		# for now we're not generating enums for these
}

# Which classes are to be expected from JSON decoding
jsonmap = {
	'FHIRElement': 'NSDictionary',
	'FHIRResource': 'NSDictionary',
	
	'Int': 'Int',
	'Bool': 'Int',
	'Double': 'NSNumber',
	
	'String': 'String',
	'NSDate': 'String',
	'NSDecimalNumber': 'Double',
	'NSDate': 'String',
	'NSURL': 'String',
}

# Properties that need to be renamed because of language keyword conflicts
reservedmap = {
	'class': 'klass',
	'import': 'importFrom',
	'protocol': 'proto',
	'extension': 'ext',
	'operator': 'operatr',
}
