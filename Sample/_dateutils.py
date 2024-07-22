"""Private classes to help with date & time support."""
# 2014-2024, SMART Health IT.

import datetime
from typing import Union


class _FHIRDateTimeMixin:
    """
    Private mixin to provide helper methods for our date and time classes.

    Users of this mixin need to provide _REGEX and _FIELD properties and a from_string() method.
    """

    def __init__(self, jsonval: Union[str, None] = None):
        super().__init__()

        setattr(self, self._FIELD, None)

        if jsonval is not None:
            if not isinstance(jsonval, str):
                raise TypeError("Expecting string when initializing {}, but got {}"
                    .format(type(self), type(jsonval)))
            if not self._REGEX.fullmatch(jsonval):
                raise ValueError("does not match expected format")
            setattr(self, self._FIELD, self._from_string(jsonval))

        self._orig_json: Union[str, None] = jsonval

    def __setattr__(self, prop, value):
        if self._FIELD == prop:
            self._orig_json = None
        object.__setattr__(self, prop, value)

    @property
    def isostring(self) -> Union[str, None]:
        """
        Returns a standardized ISO 8601 version of the Python representation of the FHIR JSON.

        Note that this may not be a fully accurate version of the input JSON.
        In particular, it will convert partial dates like "2024" to full dates like "2024-01-01".
        It will also normalize the timezone, if present.
        """
        py_value = getattr(self, self._FIELD)
        if py_value is None:
            return None
        return py_value.isoformat()

    def as_json(self) -> Union[str, None]:
        """Returns the original JSON string used to create this instance."""
        if self._orig_json is not None:
            return self._orig_json
        return self.isostring

    @classmethod
    def with_json(cls, jsonobj: Union[str, list]):
        """ Initialize a date from an ISO date string.
        """
        if isinstance(jsonobj, str):
            return cls(jsonobj)

        if isinstance(jsonobj, list):
            return [cls(jsonval) for jsonval in jsonobj]

        raise TypeError("`cls.with_json()` only takes string or list of strings, but you provided {}"
            .format(type(jsonobj)))

    @classmethod
    def with_json_and_owner(cls, jsonobj: Union[str, list], owner):
        """ Added for compatibility reasons to FHIRElement; "owner" is
        discarded.
        """
        return cls.with_json(jsonobj)

    @staticmethod
    def _strip_leap_seconds(value: str) -> str:
        """
        Manually ignore leap seconds by clamping the seconds value to 59.

        Python native times don't support them (at the time of this writing, but also watch
        https://bugs.python.org/issue23574). For example, the stdlib's datetime.fromtimestamp()
        also clamps to 59 if the system gives it leap seconds.

        But FHIR allows leap seconds and says receiving code SHOULD accept them,
        so we should be graceful enough to at least not throw a ValueError,
        even though we can't natively represent the most-correct time.
        """
        # We can get away with such relaxed replacement because we are already regex-certified
        # and ":60" can't show up anywhere but seconds.
        return value.replace(":60", ":59")

    @staticmethod
    def _parse_partial(value: str, date_cls):
        """
        Handle partial dates like 1970 or 1980-12.

        FHIR allows them, but Python's datetime classes do not natively parse them.
        """
        # Note that `value` has already been regex-certified by this point,
        # so we don't have to handle really wild strings.
        if len(value) < 10:
            pieces = value.split("-")
            if len(pieces) == 1:
                return date_cls(int(pieces[0]), 1, 1)
            else:
                return date_cls(int(pieces[0]), int(pieces[1]), 1)
        return date_cls.fromisoformat(value)

    @classmethod
    def _parse_date(cls, value: str) -> datetime.date:
        return cls._parse_partial(value, datetime.date)

    @classmethod
    def _parse_datetime(cls, value: str) -> datetime.datetime:
        # Until we depend on Python 3.11+, manually handle Z
        value = value.replace("Z", "+00:00")
        value = cls._strip_leap_seconds(value)
        return cls._parse_partial(value, datetime.datetime)

    @classmethod
    def _parse_time(cls, value: str) -> datetime.time:
        value = cls._strip_leap_seconds(value)
        return datetime.time.fromisoformat(value)
