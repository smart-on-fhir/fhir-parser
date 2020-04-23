import sys

import typer

from . import fhirloader, fhirspec
from .generators.python_pydantic import settings


app = typer.Typer()

@app.command()
def main(
    force_download: bool = False,
    dry_run: bool = False,
    force_cache: bool = False,
    load_only: bool = False,
):
    """Download and parse FHIR resource definitions."""

    # assure we have all files
    loader = fhirloader.FHIRLoader(settings)
    spec_source = loader.load(force_download=force_download, force_cache=force_cache)

    # parse
    if not load_only:
        spec = fhirspec.FHIRSpec(spec_source, settings)
        if not dry_run:
            spec.write()


if __name__ == "__main__":
    app()
