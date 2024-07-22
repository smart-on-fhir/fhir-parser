"""Facilitate working with FHIR date fields."""
# 2024, SMART Health IT.

import datetime
import re
from typing import Any, Union

from ._dateutils import _FHIRDateTimeMixin


class FHIRDate(_FHIRDateTimeMixin):
    """
    A convenience class for working with FHIR dates in Python.

    http://hl7.org/fhir/R4/datatypes.html#date

    Converting to a Python representation does require some compromises:
    - This class will convert partial dates ("reduced precision dates") like "2024" into full
      dates using the earliest possible time (in this example, "2024-01-01") because Python's
      date class does not support partial dates.

    If such compromise is not useful for you, avoid using the `date` or `isostring`
    properties and just use the `as_json()` method in order to work with the original,
    exact string.

    Public properties:
    - `date`: datetime.date representing the JSON value
    - `isostring`: an ISO 8601 string version of the above Python object

    Public methods:
    - `as_json`: returns the original JSON used to construct the instance
    """

    def __init__(self, jsonval: Union[str, None] = None):
        self.date: Union[datetime.date, None] = None
        super().__init__(jsonval)

    ##################################
    # Private properties and methods #
    ##################################

    # Pulled from spec for date
    _REGEX = re.compile(r"([0-9]([0-9]([0-9][1-9]|[1-9]0)|[1-9]00)|[1-9]000)(-(0[1-9]|1[0-2])(-(0[1-9]|[1-2][0-9]|3[0-1]))?)?")
    _FIELD = "date"

    @classmethod
    def _from_string(cls, value: str) -> Any:
        return cls._parse_date(value)
