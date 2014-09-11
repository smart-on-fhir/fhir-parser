#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  Generated from FHIR {{ info.version }} ({{ info.filename }}) on {{ info.date }}.
#  Copyright (c) {{ info.year }} SMART Platforms. All rights reserved.

{% for imp in info.imports %}{% if not imp.native and not imp.inline %}
from {{ imp.name }} import {{ imp.name }}
{%- endif %}{% endfor %}

{%- for klass in classes %}


class {{ klass.className }}({{ klass.superclass|default('object')}}):
    """ {{ klass.short|replace("\n", "\n    ") }}.
{%- if klass.formal %}
    
    {{ klass.formal|replace("\n", "\n    ") }}
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
        """ {{ prop.short }}.
        Type `{{ prop.className }}`{% if prop.jsonClass != prop.className %}, in jsondict `{{ prop.jsonClass }}`{% endif %} """
    {%- endfor %}
        
        if jsondict is not None:
            self.updateWithJSON(jsondict)
    
{%- for prop in klass.properties %}{% if prop.isReferenceTo %}
    
    @property
    def {{ prop.name }}(self):
        return self._resolveReference{% if prop.isArray %}s{% endif %}("{{ prop.name }}")
    
    @{{ prop.name }}.setter
    def {{ prop.name }}(self, newValue):
        if newValue is not None:
            self._didSetReference{% if prop.isArray %}s{% endif %}(newValue, name="{{ prop.name }}")
{%- endif %}{% endfor %}    
{%- if klass.properties %}
    
    def updateWithJSON(self, jsondict):
        super({{ klass.className }}, self).updateWithJSON(jsondict)
        {%- for prop in klass.properties %}
        if '{{ prop.name }}' in jsondict:
            {%- if prop.isNative %}
            self.{{ prop.name }} = jsondict['{{ prop.name }}']
            {%- else %}
            self.{{ prop.name }} = {{ prop.className }}.withJSON(jsondict['{{ prop.name }}'])
            {%- endif %}
        {%- endfor %}
    
{%- endif %}
{%- endfor %}


