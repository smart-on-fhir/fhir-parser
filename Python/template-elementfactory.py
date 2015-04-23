#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  Generated from FHIR {{ info.version }} on {{ info.date }}.
#  {{ info.year }}, SMART Health IT.

import fhirelement


class FHIRElementFactory(object):
    """ Factory class to instantiate resources by resource name.
    """
    
    @classmethod
    def instantiate(cls, resource_name, jsondict):
        {%- for klass in classes %}{% if klass.resource_name %}
        if "{{ klass.resource_name }}" == resource_name:
            import {{ klass.module }}
            return {{ klass.module }}.{{ klass.name }}(jsondict)
        {%- endif %}{% endfor %}
        return fhirelement.FHIRElement(json)

