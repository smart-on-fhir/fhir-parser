#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  Generated from FHIR {{ info.version }} on {{ info.date }}.
#  {{ info.year }}, SMART Health IT.

from . import element


class FHIRElementFactory(object):
    """ Factory class to instantiate resources by resource name.
    """

    @classmethod
    def instantiate(cls, resource_name, jsondict, cast=False):
        """ Instantiate a resource of the type correlating to "resource_name".

        :param str resource_name: The name/type of the resource to instantiate
        :param dict jsondict: The JSON dictionary to use for data
        :returns: A resource of the respective type or None
        """

        klass = cls.get_class(resource_name)
        if klass:
            return klass(jsondict, cast)
        return None

    @classmethod
    def get_class(cls, resource_name):
        """ Get resource class of the type correlating to "resource_name".

        :param str resource_name: The name/type of the resource to instantiate
        :returns: A resource class of the respective type or None
        """

        {%- for klass in classes %}{% if klass.resource_name %}
        if "{{ klass.resource_name }}" == resource_name:
            from . import {{ klass.module }}
            return {{ klass.module }}.{{ klass.name }}
        {%- endif %}{% endfor %}
        return None