#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  Base class for all FHIR elements.

import sys
import logging
from pydantic import BaseModel

logger = logging.getLogger(__name__)


class FHIRValidationError(Exception):
    """ Exception raised when one or more errors occurred during model
    validation.
    """

    def __init__(self, errors, path=None):
        """ Initializer.
        
        :param errors: List of Exception instances. Also accepts a string,
            which is converted to a TypeError.
        :param str path: The property path on the object where errors occurred
        """
        if not isinstance(errors, list):
            errors = [TypeError(errors)]
        msgs = "\n  ".join([str(e).replace("\n", "\n  ") for e in errors])
        message = "{}:\n  {}".format(path or "{root}", msgs)

        super(FHIRValidationError, self).__init__(message)

        self.errors = errors
        """ A list of validation errors encountered. Typically contains
        TypeError, KeyError, possibly AttributeError and others. """

        self.path = path
        """ The path on the object where the errors occurred. """

    def prefixed(self, path_prefix):
        """ Creates a new instance of the receiver, with the given path prefix
        applied. """
        path = (
            "{}.{}".format(path_prefix, self.path)
            if self.path is not None
            else path_prefix
        )
        return self.__class__(self.errors, path)


class FHIRAbstractBase(BaseModel):
    """Abstract base class for all FHIR elements.
    """
