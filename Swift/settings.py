# These are settings for the FHIR class generator

from Swift.mappings import *

# the path to prepend to all filenames specified below (will be os.path.join-ed)
writepath_prepend = '..'

# classes/resources
write_resources = True
tpl_resource_source = 'Swift/template-resource.swift'		# the template to use as source
tpl_resource_target_ptrn = 'Models/{}.swift'				# where to write the output

# factory methods
write_factory = True
tpl_factory_source = 'Swift/template-elementfactory.swift'
tpl_factory_target = 'Models/FHIRElement+Factory.swift'

# search parameters
write_searchparams = True
tpl_searchparams_source = 'Swift/template-searchparams.swift'
tpl_searchparams_target = 'Models/FHIRSearchParam+Params.swift'

# unit tests
write_unittests = True
tpl_unittest_source = 'Swift/template-unittest.swift'
tpl_unittest_target_ptrn = 'SwiftFHIRTests/ModelTests/{}Tests.swift'
