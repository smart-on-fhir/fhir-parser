#!/usr/bin/env python
# -*- coding: utf-8 -*-

import io
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
    
    def render():
        """ The main rendering start point, for subclasses to override.
        """
        raise Exception("Cannot use abstract superclass' `render` method")
    
    def do_render(self, data, template_path, target_path):
        """ Render the given data using a Jinja2 template, writing to the file
        at the target path.
        
        :param template_path: Path to the Jinja2 template to render
        :param target_path: Output path
        """
        assert os.path.exists(template_path)
        template = jinjaenv.get_template(template_path)
        
        if not target_path:
            raise Exception("No target filepath provided")
        dirpath = os.path.dirname(target_path)
        if not os.path.isdir(dirpath):
            os.makedirs(dirpath)
        
        with io.open(target_path, 'w', encoding='utf-8') as handle:
            logging.info('Writing {}'.format(target_path))
            rendered = template.render(data)
            handle.write(rendered)
            # handle.write(rendered.encode('utf-8'))


class FHIRProfileRenderer(FHIRRenderer):
    """ Write classes for a profile.
    """    
    def copy_files(self):
        """ Copy base resources to the target location, according to settings.
        """
        for filepath, module, contains in self.settings.resource_baseclasses:
            if os.path.exists(filepath):
                tgt = os.path.join(self.settings.resource_base_target, os.path.basename(filepath))
                logging.info("Copying baseclasses in {} to {}".format(os.path.basename(filepath), tgt))
                shutil.copyfile(filepath, tgt)
    
    def render(self):
        for pname, profile in self.spec.profiles.items():
            classes = sorted(profile.writable_classes(), key=lambda x: x.name)
            if 0 == len(classes):
                logging.info('Profile "{}" returns zero writable classes, skipping'.format(profile.filename))
                return
            
            imports = profile.needed_external_classes()
            data = {
                'profile': profile,
                'info': self.spec.info,
                'imports': imports,
                'classes': classes
            }
            
            ptrn = profile.targetname.lower() if self.settings.resource_modules_lowercase else profile.targetname
            source_path = self.settings.tpl_resource_source
            target_path = self.settings.tpl_resource_target_ptrn.format(ptrn)
            
            self.do_render(data, source_path, target_path)


class FHIRFactoryRenderer(FHIRRenderer):
    """ Write factories for FHIR classes.
    """
    def render(self):
        classes = []
        for pname, profile in self.spec.profiles.items():
            classes.extend(profile.writable_classes())
        
        data = {
            'info': self.spec.info,
            'classes': sorted(classes, key=lambda x: x.name),
        }
        self.do_render(data, self.settings.tpl_factory_source, self.settings.tpl_factory_target)



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

