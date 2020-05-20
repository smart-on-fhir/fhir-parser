import sys
import importlib
from pathlib import Path

import typer

from . import fhirspec, logger
from .specificationcache import SpecificationCache


app = typer.Typer()


@app.command()
def main(
    force_download: bool = False,
    dry_run: bool = False,
    load_only: bool = False,
    generator: str = "python_pydantic",
    output_directory: Path = Path("output"),
    download_cache: Path = Path("./downloads"),
):
    """Download and parse FHIR resource definitions."""

    logger.setup_logging()

    generator_module = f"fhirzeug.generators.{generator}.settings"

    # todo make this disappear and replace it with
    generator_settings = importlib.import_module(generator_module)

    generator_settings.tpl_resource_target = str(output_directory)

    # assure we have all files
    loader = SpecificationCache(generator_settings.specification_url, download_cache)
    loader.sync(force_download=force_download,)

    # parse
    if not load_only:
        spec = fhirspec.FHIRSpec(
            str(loader.cache_dir), generator_settings, generator_module
        )
        if not dry_run:
            spec.write()


if __name__ == "__main__":
    app()
