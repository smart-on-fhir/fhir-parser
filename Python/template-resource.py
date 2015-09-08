#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  Generated from FHIR {{ info.version }} ({{ profile.url }}) on {{ info.date }}.
#  {{ info.year }}, SMART Health IT.

{% for imp in imports %}
from . import {{ imp.module }}
{%- endfor %}

{%- for klass in classes %}


class {{ klass.name }}({% if klass.superclass in imports %}{{ klass.superclass.module }}.{% endif -%}
    {{ klass.superclass.name|default('object')}}):
    """ {{ klass.short|wordwrap(width=75, wrapstring="\n    ") }}.
{%- if klass.formal %}
    
    {{ klass.formal|wordwrap(width=75, wrapstring="\n    ") }}
{%- endif %}
    """
{%- if klass.resource_name %}
    
    resource_name = "{{ klass.resource_name }}"
{%- endif %}
    
    def __init__(self, jsondict=None):
        """ Initialize all valid properties.
        """
    {%- for prop in klass.properties %}
        
        self.{{ prop.name }} = None
        """ {{ prop.short|wordwrap(67, wrapstring="\n        ") }}.
        {% if prop.is_array %}List of{% else %}Type{% endif %} `{{ prop.class_name }}`{% if prop.is_array %} items{% endif %}
        {%- if prop.reference_to_names|length > 0 %} referencing `{{ prop.reference_to_names|join(', ') }}`{% endif %}
        {%- if prop.json_class != prop.class_name %} (represented as `{{ prop.json_class }}` in JSON){% endif %}. """
    {%- endfor %}
        
        super({{ klass.name }}, self).__init__(jsondict)
    
{%- if klass.properties %}
    
    def elementProperties(self):
        js = super({{ klass.name }}, self).elementProperties()
        js.extend([
        {%- for prop in klass.properties %}
            ("{{ prop.name }}", "{{ prop.orig_name }}",
            {%- if prop.module_name %} {{ prop.module_name }}.{% else %} {% endif %}{{ prop.class_name }}, {{ prop.is_array }}),
        {%- endfor %}
        ])
        return js
    
{%- endif %}
{%- endfor %}


