# These are settings for the FHIR class generator

from Swift3Realm.mappings import *

# Base URL for where to load specification data from
specification_url = 'http://hl7.org/fhir/dstu2/'
#specification_url = 'http://hl7.org/fhir/2016May/'
#specification_url = 'http://hl7-fhir.github.io'

# Whether and where to put the generated class models
write_resources = True
tpl_resource_target_ptrn = '../Models/{}.swift'             # where to write the generated class files to, with one "{}" placeholder for the class name

# Whether and where to put the factory methods
write_factory = write_resources        # required in Swift
tpl_factory_target = '../Models/FHIRAbstractBase+Factory.swift'

# Whether and where to write unit tests
write_unittests = True
tpl_unittest_target_ptrn = '../Tests/ModelTests/{}Tests.swift'  # a pattern to determine the output files for unit tests; the one placeholder will be the class name


##
##  Know what you do when changing the following settings
##


# classes/resources
default_base = {
    'complex-type': 'FHIRAbstractBase',                 # for "Element"
    'resource': 'FHIRAbstractResource',                 # for "Resource"
}
resource_modules_lowercase = False                      # whether all resource paths (i.e. modules) should be lowercase
tpl_resource_source = 'Swift3Realm/template-resource.swift'   # the template to use as source when writing resource implementations for profiles
manual_profiles = [                                     # all these profiles should be copied to dirname(`tpl_resource_target_ptrn`): tuples of (path, module, profile-name-list)
    ('Swift3Realm/FHIRAbstractBase.swift', None, ['FHIRAbstractBase']),
    ('Swift3Realm/FHIRAbstractResource.swift', None, ['FHIRAbstractResource']),
    ('Swift3Realm/FHIRTypes.swift', None, [
    	'boolean',
    	'string', 'base64Binary', 'code', 'id',
    	'decimal', 'integer', 'positiveInt', 'unsignedInt',
    	'uri', 'oid', 'uuid',
    ]),
    ('Swift3Realm/DateAndTime.swift', None, [
        'date', 'dateTime', 'time', 'instant',
    ]),
    ('Swift3Realm/JSON-extensions.swift', None, []),
    ('Swift3Realm/FHIRServer.swift', None, []),
    ('Swift3Realm/FHIRServerResponse.swift', None, []),
    ('Swift3Realm/FHIRError.swift', None, []),
    ('Swift3Realm/RealmTypes.swift', None, []),
]

# factory methods
tpl_factory_source = 'Swift3Realm/template-elementfactory.swift'

# search parameters
write_searchparams = False
search_generate_camelcase = True
tpl_searchparams_source = ''
tpl_searchparams_target = ''

# unit tests
tpl_unittest_source = 'Swift3Realm/template-unittest.swift'
unittest_copyfiles = [
    'Swift3Realm/XCTestCase+FHIR.swift',
    'Swift3Realm/DateAndTimeTests.swift',
    'Swift3Realm/RealmTestingProtocols.swift'
]
unittest_format_path_prepare = '{}?'            # used to format `path` before appending another path element - one placeholder for `path`
unittest_format_path_key = '{}.{}'              # used to create property paths by appending `key` to the existing `path` - two placeholders
unittest_format_path_index = '{}[{}]'          # used for array properties - two placeholders, `path` and the array index
