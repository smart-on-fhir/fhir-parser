#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  Base class for FHIR resources.
#  2014, SMART Health IT.

from . import fhirabstractbase


class FHIRAbstractResource(fhirabstractbase.FHIRAbstractBase):
    """ Extends the FHIRAbstractBase with server talking capabilities.
    """

    resource_type = "FHIRAbstractResource"
