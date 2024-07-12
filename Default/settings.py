# These are settings for the FHIR class generator.
# All paths are relative to the `fhir-parser` directory. You can use '/' to
# indicate directories: the parser will split them on '/' and use os.path to
# make them platform independent.

from Default.mappings import *


# Base URL for where to load specification data from
specification_url = 'http://hl7.org/fhir/R4'
#specification_url = 'http://build.fhir.org'

# To which directory to download to
download_directory = 'downloads'

# In which directory to find the templates. See below for settings that start with `tpl_`: these are the template names.
tpl_base = 'Sample'

# Whether and where to put the generated class models
write_resources = True
tpl_resource_source = 'template-resource.py'          # the template to use as source when writing resource implementations for profiles
tpl_resource_target = '../models'                     # target directory to write the generated class files to
tpl_resource_target_ptrn = '{}.py'                    # target class file name pattern, with one placeholder (`{}`) for the class name
tpl_codesystems_source = 'template-codesystems.py'    # the template to use as source when writing enums for CodeSystems; can be `None`
tpl_codesystems_target_ptrn = 'codesystem_{}.py'      # the filename pattern to use for generated code systems and value sets, with one placeholder (`{}`) for the class name

# Whether and where to put the factory methods and the dependency graph
write_factory = True
tpl_factory_source = 'template-elementfactory.py'       # the template to use for factory generation
tpl_factory_target = '../models/fhirelementfactory.py'  # where to write the generated factory to
write_dependencies = False
tpl_dependencies_source = 'template-dependencies.json'  # template used to render the JSON dependency graph
tpl_dependencies_target = './dependencies.json'         # write dependency JSON to project root

# Whether and where to write unit tests
write_unittests = True
tpl_unittest_source = 'template-unittest.py'    # the template to use for unit test generation
tpl_unittest_target = '../models'               # target directory to write the generated unit test files to
tpl_unittest_target_ptrn = '{}_test.py'         # target file name pattern for unit tests; the one placeholder (`{}`) will be the class name
unittest_copyfiles = []                         # array of file names to copy to the test directory `tpl_unittest_target` (e.g. unit test base classes)

unittest_format_path_prepare = '{}'        # used to format `path` before appending another path element - one placeholder for `path`
unittest_format_path_key = '{}.{}'         # used to create property paths by appending `key` to the existing `path` - two placeholders
unittest_format_path_index = '{}[{}]'      # used for array properties - two placeholders, `path` and the array index

# Settings for classes and resources
default_base = {
    'complex-type': 'FHIRAbstractBase',    # the class to use for "Element" types
    'resource': 'FHIRAbstractResource',    # the class to use for "Resource" types
}
resource_modules_lowercase = True          # whether all resource paths (i.e. modules) should be lowercase
camelcase_classes = True                   # whether class name generation should use CamelCase
camelcase_enums = True                     # whether names for enums should be camelCased
backbone_class_adds_parent = True          # if True, backbone class names prepend their parent's class name

# All these files should be copied to `tpl_resource_target`: tuples of (path/to/file, module, array-of-class-names)
# If the path is None, no file will be copied but the class names will still be recognized and it is assumed the class is present.
manual_profiles = [
    ('Sample/fhirabstractbase.py', 'fhirabstractbase', [
        'boolean',
        'string', 'base64Binary', 'code', 'id',
        'decimal', 'integer', 'unsignedInt', 'positiveInt',
        'uri', 'oid', 'uuid',
        'FHIRAbstractBase',
    ]),
    ('Sample/fhirabstractresource.py', 'fhirabstractresource', ['FHIRAbstractResource']),
    ('Sample/fhirreference.py', 'fhirreference', ['FHIRReference']),
    ('Sample/fhirdate.py', 'fhirdate', ['date', 'dateTime', 'instant', 'time']),
]
