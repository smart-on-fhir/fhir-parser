"""Facilitate working with FHIR datetime fields."""
# 2024, SMART Health IT.

import datetime
import re
from typing import Any, Union

from ._dateutils import _FHIRDateTimeMixin


class FHIRDateTime(_FHIRDateTimeMixin):
    """
    A convenience class for working with FHIR datetimes in Python.

    http://hl7.org/fhir/R4/datatypes.html#datetime

    Converting to a Python representation does require some compromises:
    - This class will convert partial dates ("reduced precision dates") like "2024" into full
      naive datetimes using the earliest possible time (in this example, "2024-01-01T00:00:00")
      because Python's datetime class does not support partial dates.
    - FHIR allows arbitrary sub-second precision, but Python only holds microseconds.
    - Leap seconds (:60) will be changed to the 59th second (:59) because Python's time classes
      do not support leap seconds.

    If such compromise is not useful for you, avoid using the `datetime` or `isostring`
    properties and just use the `as_json()` method in order to work with the original,
    exact string.

    Public properties:
    - `datetime`: datetime.datetime representing the JSON value (naive or aware)
    - `isostring`: an ISO 8601 string version of the above Python object

    Public methods:
    - `as_json`: returns the original JSON used to construct the instance
    """

    def __init__(self, jsonval: Union[str, None] = None):
        self.datetime: Union[datetime.datetime, None] = None
        super().__init__(jsonval)

    ##################################
    # Private properties and methods #
    ##################################

    # Pulled from spec for datetime
    _REGEX = re.compile(r"([0-9]([0-9]([0-9][1-9]|[1-9]0)|[1-9]00)|[1-9]000)(-(0[1-9]|1[0-2])(-(0[1-9]|[1-2][0-9]|3[0-1])(T([01][0-9]|2[0-3]):[0-5][0-9]:([0-5][0-9]|60)(\.[0-9]+)?(Z|(\+|-)((0[0-9]|1[0-3]):[0-5][0-9]|14:00)))?)?)?")
    _FIELD = "datetime"

    @classmethod
    def _from_string(cls, value: str) -> Any:
        return cls._parse_datetime(value)
