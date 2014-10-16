#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  Generated from FHIR {{ info.version }} ({{ info.filename }}) on {{ info.date }}.
#  {{ info.year }}, SMART Platforms.

# We need to support importing other generated classes without relying on the
# models being part of a specific module. To do so we prepend the current
# directory sys.path - better solutions are welcome!
import sys
import os.path
abspath = os.path.abspath(os.path.dirname(__file__))
if abspath not in sys.path:
    sys.path.insert(0, abspath)

{% for imp in info.imports %}
import {{ imp }}
{%- endfor %}

{%- for klass in classes %}


class {{ klass.className }}({% if klass.superclass in info.imports %}{{ klass.superclass }}.{% endif %}{{ klass.superclass|default('object')}}):
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
        {%- if prop.isReferenceTo %} referencing `{{ prop.isReferenceTo }}`{% endif %}
        {%- if prop.jsonClass != prop.className %} (represented as `{{ prop.jsonClass }}` in JSON){% endif %}. """
    {%- endfor %}
        
        super({{ klass.className }}, self).__init__(jsondict)
    
{%- if klass.properties %}
    
    def update_with_json(self, jsondict):
        super({{ klass.className }}, self).update_with_json(jsondict)
        {%- for prop in klass.properties %}
        if '{{ prop.name }}' in jsondict:
            {%- if prop.isNative %}
            self.{{ prop.name }} = jsondict['{{ prop.name }}']
            {%- else %}{% if prop.isReferenceTo %}
            self.{{ prop.name }} = {% if prop.className in info.imports %}{{ prop.className }}.{% endif -%}
                {{ prop.className }}.with_json_and_owner(jsondict['{{ prop.name }}'], self, {% if prop.isReferenceTo in info.imports %}{{ prop.isReferenceTo }}.{% endif -%}
                {{ prop.isReferenceTo }})
            {%- else %}
            self.{{ prop.name }} = {% if prop.className in info.imports %}{{ prop.className }}.{% endif -%}
                {{ prop.className }}.with_json(jsondict['{{ prop.name }}'])
            {%- endif %}{% endif %}
        {%- endfor %}
    
{%- endif %}
{%- endfor %}


