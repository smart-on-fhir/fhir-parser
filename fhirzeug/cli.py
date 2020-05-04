import sys
import importlib
from pathlib import Path

import typer

from . import fhirloader, fhirspec


app = typer.Typer()


@app.command()
def main(
    force_download: bool = False,
    dry_run: bool = False,
    force_cache: bool = False,
    load_only: bool = False,
    generator: str = "python_pydantic",
    output_directory: Path = Path("output"),
):
    """Download and parse FHIR resource definitions."""

    generator_module = f"fhirzeug.generators.{generator}.settings"

    generator_settings = importlib.import_module(generator_module)

    generator_settings.tpl_resource_target = str(output_directory)

    # assure we have all files
    loader = fhirloader.FHIRLoader(generator_settings)
    spec_source = loader.load(force_download=force_download, force_cache=force_cache)

    # parse
    if not load_only:
        spec = fhirspec.FHIRSpec(spec_source, generator_settings, generator_module)
        if not dry_run:
            spec.write()


if __name__ == "__main__":
    app()
