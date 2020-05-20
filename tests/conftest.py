from pathlib import Path

import pytest

from fhirzeug.specificationcache import SpecificationCache
from fhirzeug.fhirspec import FHIRSpec


@pytest.fixture(scope="session")
def specification_settings():
    """A spec cache of r4"""
    from fhirzeug.generators.python import settings

    return settings


@pytest.fixture(scope="session")
def specification_cache():
    """A spec cache of r4"""
    cache = SpecificationCache("http://hl7.org/fhir/R4", Path("downloads"))
    cache.sync()
    return cache


@pytest.fixture(scope="session")
def spec(specification_cache: SpecificationCache, specification_settings):
    return FHIRSpec(
        specification_cache.cache_dir,
        specification_settings,
        "fhirzeug.generators.python_pydantic",
    )
