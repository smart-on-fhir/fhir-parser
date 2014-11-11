#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  Generated from FHIR {{ info.version }} ({{ info.filename }}) on {{ info.date }}.
#  {{ info.year }}, SMART Platforms.

{% for imp in info.imports %}
import {% if info.lowercase_import_hack %}{{ imp|lower }}{% else %}{{ imp }}{% endif %}
{%- endfor %}

{%- for klass in classes %}


class {{ klass.className }}({% if klass.superclass in info.imports %}
    {%- if info.lowercase_import_hack %}{{ klass.superclass|lower }}{% else %}{{ klass.superclass }}{% endif %}.{% endif -%}
    {{ klass.superclass|default('object')}}):
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
            self.{{ prop.name }} = {% if prop.className in info.imports %}
                {%- if info.lowercase_import_hack %}{{ prop.className|lower }}{% else %}{{ prop.className }}{% endif %}.{% endif -%}
                {{ prop.className }}.with_json_and_owner(jsondict['{{ prop.name }}'], self, {% if prop.isReferenceTo in info.imports %}
                    {%- if info.lowercase_import_hack %}{{ prop.isReferenceTo|lower }}{% else %}{{ prop.isReferenceTo }}{% endif %}.{% endif -%}
                {{ prop.isReferenceTo }})
            {%- else %}
            self.{{ prop.name }} = {% if prop.className in info.imports %}
                {%- if info.lowercase_import_hack %}{{ prop.className|lower }}{% else %}{{ prop.className }}{% endif %}.{% endif -%}
                {{ prop.className }}.with_json_and_owner(jsondict['{{ prop.name }}'], self)
            {%- endif %}{% endif %}
        {%- endfor %}
    
{%- endif %}
{%- endfor %}


