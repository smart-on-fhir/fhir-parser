#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import io
import re
import logging
import textwrap

from jinja2 import Environment, PackageLoader
from jinja2.filters import environmentfilter

jinjaenv = Environment(loader=PackageLoader('generate', '.'))


class FHIRRenderer(object):
    def __init__(self, spec, settings):
        self.spec = spec
        self.settings = settings
    
    def do_render(self, data, source_path, target_path):
        """ Render the given data using the source Jinja2 template, writing
        the output into the file at the target location.
        """
        assert(os.path.exists(source_path))
        template = jinjaenv.get_template(source_path)
        
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
    
    def render(self, profile):
        inline = set()
        checked = set()
        imports = []
        
        # classes defined in the profile
        for klass in profile.classes:
            inline.add(klass.name)
        
        for klass in profile.classes:
            # are there superclasses that we need to import?
            sup = klass.superclass
            if sup is not None and sup not in checked:
                checked.add(sup)
                if sup not in self.settings.natives and sup not in inline:
                    imports.append(sup)
            
            # look at all properties' classes
            for prop in klass.properties:
                prop_class = prop.klass.name
                if prop_class not in checked:
                    checked.add(prop_class)
                    if prop_class not in self.settings.natives and prop_class not in inline:
                        imports.append(prop_class)
                
                # is the property a reference to a certain class?
                refTo = prop.is_reference_to
                if refTo is not None and refTo not in checked:
                    checked.add(refTo)
                    if refTo not in self.settings.natives and refTo not in inline:
                        imports.append(refTo)
        
        # info['lowercase_import_hack'] = self.settings.ptrn_filenames_lowercase
        # classes = sorted(profile.classes, key=lambda x: x.name)
        classes = profile.classes
        
        ptrn = profile.name.lower() if self.settings.ptrn_filenames_lowercase else profile.name
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

