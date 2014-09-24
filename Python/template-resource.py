#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  Generated from FHIR {{ info.version }} ({{ info.filename }}) on {{ info.date }}.
#  Copyright (c) {{ info.year }} SMART Platforms. All rights reserved.

# We need to support importing other generated classes without relying on the
# models being part of a specific module. To do so we prepend the current
# directory sys.path - better solutions are welcome!
import sys
import os.path
abspath = os.path.abspath(os.path.dirname(__file__))
if abspath not in sys.path:
    sys.path.insert(0, abspath)

{% for imp in info.imports %}{% if not imp.native and not imp.inline %}
from {{ imp.name }} import {{ imp.name }}
{%- endif %}{% endfor %}

{%- for klass in classes %}


class {{ klass.className }}({{ klass.superclass|default('object')}}):
    """ {{ klass.short|wordwrap(width=75, wrapstring="\n    ") }}.
{%- if klass.formal %}
    
    {{ klass.formal|wordwrap(width=75, wrapstring="\n    ") }}
{%- endif %}
    """
{%- if klass.resourceName %}
    
    resource_name = "{{ klass.resourceName }}"
{%- endif %}
    
    def __init__(self, jsondict=None):
        """ Initialize all valid properties.
        """
    {%- for prop in klass.properties %}
        
        self.{{ prop.name }} = {% if "bool" == prop.className %}False{% else %}None{% endif %}
        """ {{ prop.short|wordwrap(67, wrapstring="\n        ") }}.
        {% if prop.isArray %}List of{% else %}Type{% endif %} `{{ prop.className }}`{% if prop.isArray %} items{% endif %}
        {%- if prop.jsonClass != prop.className %} (represented as `{{ prop.jsonClass }}` in JSON){% endif %}. """
    {%- endfor %}
        
        if jsondict is not None:
            self.update_with_json(jsondict)
    
{%- for prop in klass.properties %}{% if prop.isReferenceTo %}
    
    @property
    def {{ prop.name }}(self):
        return self._resolve_reference{% if prop.isArray %}s{% endif %}("{{ prop.name }}")
    
    @{{ prop.name }}.setter
    def {{ prop.name }}(self, newValue):
        if newValue is not None:
            self._did_set_reference{% if prop.isArray %}s{% endif %}(newValue, name="{{ prop.name }}")
{%- endif %}{% endfor %}    
{%- if klass.properties %}
    
    def update_with_json(self, jsondict):
        super(self.__class__, self).update_with_json(jsondict)
        {%- for prop in klass.properties %}
        if '{{ prop.name }}' in jsondict:
            {%- if prop.isNative %}
            self.{{ prop.name }} = jsondict['{{ prop.name }}']
            {%- else %}
            self.{{ prop.name }} = {{ prop.className }}.with_json(jsondict['{{ prop.name }}'])
            {%- endif %}
        {%- endfor %}
    
{%- endif %}
{%- endfor %}


