# These are settings for the FHIR class generator

from Swift.mappings import *

# where to load the specification archive from
#specification_url = 'http://hl7.org/documentcenter/public/standards/FHIR/fhir-spec.zip'
specification_url = 'http://hl7-fhir.github.io/fhir-spec.zip'

# classes/resources
write_resources = True
resource_modules_lowercase = False							# whether all resource paths (i.e. modules) should be lowercase
tpl_resource_source = 'Swift/template-resource.swift'		# the template to use as source when writing resource implementations for profiles
tpl_resource_target_ptrn = '../Models/{}.swift'             # where to write the generated class files to, with one placeholder for the class name
resource_base_target = '../Models/'                         # resource target directory, likely the same as `tpl_resource_target_ptrn` without the filename pattern
resource_default_base = 'FHIRElement'                       # the default superclass to use
resource_baseclasses = [                                    # all these files should be copied to `resource_base_target`: tuples of (path, module, class-name-list)
    ('Swift/FHIRElement.swift', None, ['FHIRElement']),
    ('Swift/FHIRResource.swift', None, ['FHIRResource']),
    ('Swift/FHIRReference.swift', None, ['FHIRReference']),
    ('Swift/FHIRContainedResource.swift', None, ['FHIRContainedResource']),
    ('Swift/FHIRSearchParam.swift', None, ['FHIRSearchParam']),
    ('Swift/JSON-extensions.swift', None, []),
]

# factory methods
write_factory = False
tpl_factory_source = 'Swift/template-elementfactory.swift'
tpl_factory_target = '../Models/FHIRElement+Factory.swift'

# search parameters
write_searchparams = True
search_generate_camelcase = True
tpl_searchparams_source = 'Swift/template-searchparams.swift'
tpl_searchparams_target = '../Models/FHIRSearchParam+Params.swift'

# unit tests
write_unittests = True
tpl_unittest_source = 'Swift/template-unittest.swift'
tpl_unittest_target_ptrn = '../SwiftFHIRTests/ModelTests/{}Tests.swift'
unittest_copyfiles_base = '../SwiftFHIRTests/ModelTests/'	# Where to copy `unittest_copyfiles`
unittest_copyfiles = [
    'Swift/FHIRModelTestCase.swift',
]
unittest_filename_prefix = ''
unittest_format_path_prepare = '{}!'            # used to format `path` before appending another path element - one placeholder for `path`
unittest_format_path_key = '{}.{}'              # used to create property paths by appending `key` to the existing `path` - two placeholders
unittest_format_path_index = '{}![{}]'          # used for array properties - two placeholders, `path` and the array index
