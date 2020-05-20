import io
from pathlib import Path
import os.path
import shutil
import zipfile

import requests

from .logger import logger


def safe_pathname(filename: str) -> str:
    """Generate a safe pathname out of the string passed"""
    return "".join(
        [c for c in filename if c.isalpha() or c.isdigit() or c == " "]
    ).rstrip()


class SpecificationCache(object):
    """ Class to download, cache and manage specifications.
    
    Attributes:
        needs   The pre known content of a file
    """

    needs = {
        "version.info": "version.info",
        "valuesets.json": "examples-json.zip",
    }

    def __init__(self, base_url: str, cache_dir: Path):
        self.base_url = base_url
        self.cache_dir = cache_dir.joinpath(safe_pathname(base_url))

    def sync(self, force_download: bool = False) -> Path:
        """ Makes sure all the files needed have been downloaded.
        
        :returns: The path to the directory with all our files.
        """

        if force_download and self.cache_dir.exists():
            shutil.rmtree(self.cache_dir, ignore_errors=True)

        self.cache_dir.mkdir(parents=True, exist_ok=True)

        # check all files and download if missing
        for local, remote in self.needs.items():
            local_source_path = self.cache_dir.joinpath(remote)
            local_target_path = self.cache_dir.joinpath(local)

            logger.debug("Does {} exist?".format(local))
            if not local_target_path.exists():
                logger.info("Downloading {}".format(remote))
                self.download(remote, local_source_path)

                # unzip
                if str(local_source_path).endswith(".zip"):
                    logger.info("Extracting {}".format(local))
                    self.expand(local_source_path)

    def download(self, remote: str, local: Path) -> None:
        """ Download the given file located on the server.
        
        :returns: The local file name in our cache directory the file was
            downloaded to
        """
        url = self.base_url + "/" + remote
        res = requests.get(url)
        res.raise_for_status()

        with local.open("wb") as handle:
            for chunk in res.iter_content():
                handle.write(chunk)

    def expand(self, local_path):
        """ Expand the ZIP file at the given path to the cache directory.
        """
        with zipfile.ZipFile(local_path) as z:
            z.extractall(self.cache_dir)
