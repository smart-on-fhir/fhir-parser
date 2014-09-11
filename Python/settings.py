# These are settings for the FHIR class generator

from Python.mappings import *

# where to load the specification archive from
specification_url = 'http://hl7.org/documentcenter/public/standards/FHIR/fhir-spec.zip'

# the path to prepend to all filenames specified below (will be os.path.join-ed)
writepath_prepend = '..'

# to how many lines to wrap comments
wrap_after = 76

# classes/resources
write_resources = True
tpl_resource_source = 'Python/template-resource.py'		# the template to use as source
tpl_resource_target_ptrn = 'models/{}.py'				# where to write the output

# factory methods
write_factory = False
tpl_factory_source = 'Python/template-elementfactory.py'
tpl_factory_target = 'models/FHIRElement+Factory.py'

# search parameters
write_searchparams = False
tpl_searchparams_source = 'Python/template-searchparams.py'
tpl_searchparams_target = 'models/FHIRSearchParam+Params.py'

# unit tests
write_unittests = False
tpl_unittest_source = 'Python/template-unittest.py'
tpl_unittest_target_ptrn = 'tests/{}_tests.py'
