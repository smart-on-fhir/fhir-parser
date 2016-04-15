#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  Facilitate working with dates.
#  2014, SMART Health IT.

import sys
import isodate
import datetime


class FHIRDate(object):
    """ Facilitate working with dates.

    - `date`: datetime object representing the receiver's date-time
    """

    def __init__(self, jsonval=None, cast=False):
        self.date = None
        if isinstance(jsonval, str) or (sys.version_info[0] < 3 and isinstance(jsonval, basestring)):
            try:
                if 'T' in jsonval:
                    self.date = isodate.parse_datetime(jsonval)
                else:
                    self.date = isodate.parse_date(jsonval)
            except ValueError: pass
        elif isinstance(jsonval, (datetime.date, datetime.datetime)):
            self.date = jsonval
        elif isinstance(jsonval, int):
            self.date = datetime.datetime.utcfromtimestamp(jsonval).replace(tzinfo=None)
        if cast:
            self.origval = self.date.isoformat() \
                if isinstance(self.date, (datetime.date, datetime.datetime)) else self.date
        else:
            self.origval = jsonval

    def __setattr__(self, prop, value):
        if 'date' == prop:
            self.origval = None
        object.__setattr__(self, prop, value)

    @property
    def isostring(self):
        if self.date is None:
            return None
        if isinstance(self.date, datetime.datetime):
            return isodate.datetime_isoformat(self.date)
        return isodate.date_isoformat(self.date)

    @classmethod
    def with_json(cls, jsonobj, cast=False):
        """ Initialize a date from an ISO date string.
        """
        if isinstance(jsonobj, list):
            arr = []
            for jsonval in jsonobj:
                arr.append(cls(jsonval, cast))
            return arr
        else:
            return cls(jsonobj, cast)

    @classmethod
    def with_json_and_owner(cls, jsonobj, owner, cast=False):
        """ Added for compatibility reasons to FHIRElement; "owner" is
        discarded.
        """
        return cls.with_json(jsonobj, cast)

    def as_json(self):
        if self.origval is not None:
            return self.origval
        return self.isostring

