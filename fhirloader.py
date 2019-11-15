#!/usr/bin/env python
# -*- coding: utf-8 -*-

import io
import os.path
from logger import logger


class FHIRLoader(object):
    """ Class to download the files needed for the generator.
    
    The `needs` dictionary contains as key the local file needed and how to
    get it from the specification URL.
    """
    needs = {
        'version.info': 'version.info',
        'profiles-resources.json': 'examples-json.zip',
    }
    
    def __init__(self, settings):
        self.settings = settings
        self.base_url = settings.specification_url
        self.cache = os.path.join(*settings.download_directory.split('/'))
    
    def load(self, force_download=False, force_cache=False):
        """ Makes sure all the files needed have been downloaded.
        
        :returns: The path to the directory with all our files.
        """
        if force_download: assert not force_cache

        if os.path.isdir(self.cache) and force_download:
            import shutil
            shutil.rmtree(self.cache)
        
        if not os.path.isdir(self.cache):
            os.mkdir(self.cache)
        
        # check all files and download if missing
        uses_cache = False
        for local, remote in self.__class__.needs.items():
            path = os.path.join(self.cache, local)
            
            if not os.path.exists(path):
                if force_cache:
                    raise Exception('Resource missing from cache: {}'.format(local))
                logger.info('Downloading {}'.format(remote))
                filename = self.download(remote)
                
                # unzip
                if '.zip' == filename[-4:]:
                    logger.info('Extracting {}'.format(filename))
                    self.expand(filename)
            else:
                uses_cache = True
        
        if uses_cache:
            logger.info('Using cached resources, supply "-f" to re-download')
        
        return self.cache
    
    def download(self, filename):
        """ Download the given file located on the server.
        
        :returns: The local file name in our cache directory the file was
            downloaded to
        """
        import requests     # import here as we can bypass its use with a manual download
        
        url = self.base_url+'/'+filename
        path = os.path.join(self.cache, filename)
        
        ret = requests.get(url)
        if not ret.ok:
            raise Exception("Failed to download {}".format(url))
        with io.open(path, 'wb') as handle:
            for chunk in ret.iter_content():
                handle.write(chunk)
        
        return filename
    
    def expand(self, local):
        """ Expand the ZIP file at the given path to the cache directory.
        """
        path = os.path.join(self.cache, local)
        assert os.path.exists(path)
        import zipfile      # import here as we can bypass its use with a manual unzip
        
        with zipfile.ZipFile(path) as z:
            z.extractall(self.cache)

