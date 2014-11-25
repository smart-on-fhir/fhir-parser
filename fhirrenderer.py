#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import re
import shutil
import logging
import textwrap

from jinja2 import Environment, PackageLoader
from jinja2.filters import environmentfilter

jinjaenv = Environment(loader=PackageLoader('generate', '.'))


class FHIRRenderer(object):
    def __init__(self, spec, settings):
        self.spec = spec
        self.settings = settings
    
    def copy_files(self):
        for filepath, module, contains in self.settings.resource_baseclasses:
            if os.path.exists(filepath):
                tgt = os.path.join(self.settings.resource_base_target, os.path.basename(filepath))
                logging.info("Copying baseclasses in {} to {}".format(os.path.basename(filepath), tgt))
                shutil.copyfile(filepath, tgt)
    
    def do_render(self, data, source_path, target_path):
        """ Render the given data using the source Jinja2 template, writing
        the output into the file at the target location.
        """
        assert os.path.exists(source_path)
        template = jinjaenv.get_template(source_path)
        
        if not target_path:
            raise Exception("No target filepath provided")
        dirpath = os.path.dirname(target_path)
        if not os.path.isdir(dirpath):
            os.makedirs(dirpath)
        
        with open(target_path, 'w', encoding='utf-8') as handle:
            logging.info('Writing {}'.format(target_path))
            rendered = template.render(data)
            handle.write(rendered)
            # handle.write(rendered.encode('utf-8'))


class FHIRProfileRenderer(FHIRRenderer):
    """ Write classes for a profile.
    """
    
    def render(self, profile):
        # classes = sorted(profile.classes, key=lambda x: x.name)
        classes = profile.classes
        imports = profile.needs_classes()
        
        ptrn = profile.name.lower() if self.settings.resource_modules_lowercase else profile.name
        source_path = self.settings.tpl_resource_source
        target_path = self.settings.tpl_resource_target_ptrn.format(ptrn)
        self.do_render({'profile': profile, 'info': self.spec.info, 'imports': imports, 'classes': classes}, source_path, target_path)



# There is a bug in Jinja's wordwrap (inherited from `textwrap`) in that it
# ignores existing linebreaks when applying the wrap:
# https://github.com/mitsuhiko/jinja2/issues/175
# Here's the workaround:
@environmentfilter
def do_wordwrap(environment, s, width=79, break_long_words=True, wrapstring=None):
    """
    Return a copy of the string passed to the filter wrapped after
    ``79`` characters.  You can override this default using the first
    parameter.  If you set the second parameter to `false` Jinja will not
    split words apart if they are longer than `width`.
    """
    if not s:
    	return s
    
    if not wrapstring:
        wrapstring = environment.newline_sequence
    
    accumulator = []
    # Workaround: pre-split the string
    for component in re.split(r"\r?\n", s):
        # textwrap will eat empty strings for breakfirst. Therefore we route them around it.
        if len(component) is 0:
            accumulator.append(component)
            continue
        accumulator.extend(
            textwrap.wrap(component, width=width, expand_tabs=False,
                replace_whitespace=False,
                break_long_words=break_long_words)
        )
    return wrapstring.join(accumulator)

jinjaenv.filters['wordwrap'] = do_wordwrap

