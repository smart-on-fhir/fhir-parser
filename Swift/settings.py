# These are settings for the FHIR class generator

from Swift.mappings import *

# where to load the specification archive from
specification_url = 'http://hl7.org/documentcenter/public/standards/FHIR/fhir-spec.zip'

# to how many lines to wrap comments
wrap_after = 110

# classes/resources
write_resources = True
tpl_resource_source = 'Swift/template-resource.swift'		# the template to use as source
tpl_resource_target_ptrn = '../Models/{}.swift'				# where to write the output
resource_base_target = '../Models/'
resource_baseclasses = [
	'Swift/FHIRElement.swift',
	'Swift/FHIRResource.swift',
	'Swift/FHIRContainedResource.swift',
	'Swift/FHIRSearchParam.swift',
	'Swift/JSON-extensions.swift',
]

# factory methods
write_factory = True
tpl_factory_source = 'Swift/template-elementfactory.swift'
tpl_factory_target = '../Models/FHIRElement+Factory.swift'

# search parameters
write_searchparams = True
tpl_searchparams_source = 'Swift/template-searchparams.swift'
tpl_searchparams_target = '../Models/FHIRSearchParam+Params.swift'

# unit tests
write_unittests = True
tpl_unittest_source = 'Swift/template-unittest.swift'
tpl_unittest_target_ptrn = '../SwiftFHIRTests/ModelTests/{}Tests.swift'
unittest_filename_prefix = ''
unittest_format_path_prepare = '{}!'			# used to format `path` before appending another path element - one placeholder for `path`
unittest_format_path_key = '{}.{}'				# used to create property paths by appending `key` to the existing `path` - two placeholders
unittest_format_path_index = '{}![{}]'			# used for array properties - two placeholders, `path` and the array index
