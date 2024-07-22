"""Facilitate working with FHIR time fields."""
# 2024, SMART Health IT.

import datetime
import re
from typing import Any, Union

from ._dateutils import _FHIRDateTimeMixin


class FHIRTime(_FHIRDateTimeMixin):
    """
    A convenience class for working with FHIR times in Python.

    http://hl7.org/fhir/R4/datatypes.html#time

    Converting to a Python representation does require some compromises:
    - FHIR allows arbitrary sub-second precision, but Python only holds microseconds.
    - Leap seconds (:60) will be changed to the 59th second (:59) because Python's time classes
      do not support leap seconds.

    If such compromise is not useful for you, avoid using the `time` or `isostring`
    properties and just use the `as_json()` method in order to work with the original,
    exact string.

    Public properties:
    - `time`: datetime.time representing the JSON value
    - `isostring`: an ISO 8601 string version of the above Python object

    Public methods:
    - `as_json`: returns the original JSON used to construct the instance
    """

    def __init__(self, jsonval: Union[str, None] = None):
        self.time: Union[datetime.time, None] = None
        super().__init__(jsonval)

    ##################################
    # Private properties and methods #
    ##################################

    # Pulled from spec for time
    _REGEX = re.compile(r"([01][0-9]|2[0-3]):[0-5][0-9]:([0-5][0-9]|60)(\.[0-9]+)?")
    _FIELD = "time"

    @classmethod
    def _from_string(cls, value: str) -> Any:
        return cls._parse_time(value)
