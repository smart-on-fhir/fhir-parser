#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  Download and parse FHIR resource definitions
#  Supply "-f" to force a redownload of the spec
#  Supply "-c" to force using the cached spec (incompatible with "-f")
#  Supply "-d" to load and parse but not write resources
#  Supply "-l" to only download the spec
#  Supply "-k" to keep previous version of FHIR resources

import io
import os
import sys

import settings
import fhirloader
import fhirspec

_cache = "downloads"


def ensure_init_py(settings, version_info):
    """ """
    init_tpl = """# _*_ coding: utf-8 _*_\n\n__fhir_version__ = "{0}"\n""".format(
        version_info.version
    )

    for fileloc in [settings.tpl_resource_target, settings.tpl_unittest_target]:

        if os.path.exists(os.path.join(fileloc, "__init__.py")):
            lines = list()
            has_fhir_version = False
            with io.open(
                os.path.join(fileloc, "__init__.py"), "r", encoding="utf-8"
            ) as fp:
                for line in fp:
                    if "__fhir_version__" in line:
                        has_fhir_version = True
                        parts = list()
                        parts.append(line.split("=")[0])
                        parts.append('"{0}"'.format(version_info.version))

                        line = "= ".join(parts)
                    lines.append(line.strip())

            if not has_fhir_version:
                lines.append('__fhir_version__ = "{0}"\n'.format(version_info.version))

            txt = "\n".join(lines)
        else:
            txt = init_tpl

        with io.open(os.path.join(fileloc, "__init__.py"), "w", encoding="utf-8") as fp:
            fp.write(txt)


if "__main__" == __name__:

    force_download = len(sys.argv) > 1 and "-f" in sys.argv
    dry = len(sys.argv) > 1 and ("-d" in sys.argv or "--dry-run" in sys.argv)
    load_only = len(sys.argv) > 1 and ("-l" in sys.argv or "--load-only" in sys.argv)
    force_cache = len(sys.argv) > 1 and ("-c" in sys.argv or "--cache-only" in sys.argv)
    keep_previous_versions = len(sys.argv) > 1 and (
        "-k" in sys.argv or "--keep-previous-versions" in sys.argv
    )

    # assure we have all files
    loader = fhirloader.FHIRLoader(settings, _cache)
    spec_source = loader.load(force_download=force_download, force_cache=force_cache)

    # parse
    if not load_only:
        spec = fhirspec.FHIRSpec(spec_source, settings)
        if not dry:
            spec.write()

    # checks for previous version maintain handler
    previous_version_info = getattr(settings, "previous_versions", [])

    if previous_version_info and keep_previous_versions:
        # backup originals
        org_specification_url = settings.specification_url
        org_tpl_resource_target = settings.tpl_resource_target
        org_tpl_factory_target = settings.tpl_factory_target
        org_tpl_unittest_target = settings.tpl_unittest_target
        org_unittest_copyfiles = settings.unittest_copyfiles

        settings.unittest_copyfiles = []

        for version in previous_version_info:

            settings.specification_url = (
                "/".join(org_specification_url.split("/")[:-1]) + "/" + version
            )
            settings.tpl_resource_target = os.path.join(
                org_tpl_resource_target, version
            )

            parts = org_tpl_factory_target.split(os.sep)
            settings.tpl_factory_target = os.path.join(
                *(list(parts[:-1] + [version] + [parts[-1]]))
            )

            parts = org_tpl_unittest_target.split(os.sep)
            settings.tpl_unittest_target = os.path.join(
                *(list(parts[:-1] + [version] + [parts[-1]]))
            )

            # ##========>
            loader = fhirloader.FHIRLoader(settings, os.path.join(_cache, version))
            spec_source = loader.load(
                force_download=force_download, force_cache=force_cache
            )
            # parse
            if not load_only:
                spec = fhirspec.FHIRSpec(spec_source, settings)
                if not dry:
                    spec.write()
                    # ensure init py has been created
                    ensure_init_py(settings, spec.info)

        # restore originals
        settings.specification_url = org_specification_url
        settings.tpl_resource_target = org_tpl_resource_target
        settings.tpl_factory_target = org_tpl_factory_target
        settings.tpl_unittest_target = org_tpl_unittest_target
        settings.unittest_copyfiles = org_unittest_copyfiles
