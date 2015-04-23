# These are settings for the FHIR class generator

from Swift.mappings import *

# Base URL for where to load specification data from
specification_url = 'http://hl7.org/fhir/2015May/'

# classes/resources
write_resources = True
resource_modules_lowercase = False							# whether all resource paths (i.e. modules) should be lowercase
tpl_resource_source = 'Swift/template-resource.swift'		# the template to use as source when writing resource implementations for profiles
tpl_resource_target_ptrn = '../Models/{}.swift'             # where to write the generated class files to, with one placeholder for the class name
resource_base_target = '../Models/'                         # resource target directory, likely the same as `tpl_resource_target_ptrn` without the filename pattern
resource_default_base = 'FHIRResource'                      # the default superclass to use for main profile models
contained_default_base = 'Element'                          # the default superclass to use for inline-defined (backbone) models
manual_profiles = [                                         # all these profiles should be copied to `resource_base_target`: tuples of (path, module, profile-name-list)
    ('Swift/FHIRElement.swift', None, ['Element', 'BackboneElement']),
    ('Swift/FHIRResource.swift', None, ['FHIRResource']),
    ('Swift/FHIRContainedResource.swift', None, ['FHIRContainedResource']),
    ('Swift/FHIRTypes.swift', None, [
    	'boolean',
    	'string', 'base64Binary', 'code', 'id',
    	'decimal', 'integer', 'positiveInt', 'unsignedInt',
    	'uri', 'oid', 'uuid',
    ]),
    ('Swift/DateAndTime.swift', None, [
        'date', 'dateTime', 'time', 'instant',
    ]),
    ('Swift/JSON-extensions.swift', None, []),
]

# factory methods
write_factory = write_resources        # required in Swift
tpl_factory_source = 'Swift/template-elementfactory.swift'
tpl_factory_target = '../Models/FHIRElement+Factory.swift'

# search parameters
write_searchparams = False
search_generate_camelcase = True
tpl_searchparams_source = ''
tpl_searchparams_target = ''

# unit tests
write_unittests = True
tpl_unittest_source = 'Swift/template-unittest.swift'
tpl_unittest_target_ptrn = '../SwiftFHIRTests/ModelTests/{}Tests.swift'
unittest_copyfiles_base = '../SwiftFHIRTests/ModelTests/'	# Where to copy `unittest_copyfiles`
unittest_copyfiles = [
    'Swift/FHIRModelTestCase.swift',
    'Swift/DateAndTimeTests.swift'
]
unittest_format_path_prepare = '{}!'            # used to format `path` before appending another path element - one placeholder for `path`
unittest_format_path_key = '{}.{}'              # used to create property paths by appending `key` to the existing `path` - two placeholders
unittest_format_path_index = '{}![{}]'          # used for array properties - two placeholders, `path` and the array index
