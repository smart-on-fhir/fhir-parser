#!/usr/bin/env python
# -*- coding: utf-8 -*-
""" Regression tests for https://github.com/smart-on-fhir/fhir-parser/issues/51

FHIR R5 added the `integer64` primitive type (e.g. `Attachment.size` changed
from `unsignedInt` to `integer64`). Two things must hold for R5 models to
work:

1. The generator must map `integer64` to the native `int` type instead of
   emitting a bogus `Integer64` model class.
2. Generated models must accept the R5-mandated JSON serialization of
   `integer64` values, which are JSON *strings* ("JSON String (due to issues
   with precision in floating point libraries)",
   https://hl7.org/fhir/R5/datatypes.html).
"""

import os
import sys
import unittest

_HERE = os.path.dirname(os.path.abspath(__file__))
_REPO = os.path.dirname(_HERE)
for _p in (_REPO, os.path.join(_REPO, "Sample")):
    if _p not in sys.path:
        sys.path.insert(0, _p)

from Default import settings as default_settings     # noqa: E402
from fhirspec import FHIRSpec                        # noqa: E402
from fhirabstractbase import (                       # noqa: E402
    FHIRAbstractBase,
    FHIRValidationError,
)


class FakeAttachment(FHIRAbstractBase):
    """Stands in for a generated R5 `Attachment`: `size` is declared as
    native `int` once the generator maps `integer64` correctly."""

    def elementProperties(self):
        js = super(FakeAttachment, self).elementProperties()
        js.extend([("size", "size", int, False, None, False)])
        return js


class TestInteger64Mapping(unittest.TestCase):
    def setUp(self):
        # `as_class_name` only needs `.settings`, no spec download required
        self.spec = FHIRSpec.__new__(FHIRSpec)
        self.spec.settings = default_settings

    def test_integer64_maps_to_native_int(self):
        self.assertEqual("int", self.spec.class_name_for_type("integer64"))

    def test_integer64_is_native(self):
        self.assertTrue(
            self.spec.class_name_is_native(self.spec.class_name_for_type("integer64")))

    def test_neighboring_primitives_unchanged(self):
        self.assertEqual("int", self.spec.class_name_for_type("integer"))
        self.assertEqual("int", self.spec.class_name_for_type("unsignedInt"))
        self.assertEqual("int", self.spec.class_name_for_type("positiveInt"))
        self.assertEqual("float", self.spec.class_name_for_type("decimal"))
        self.assertEqual("str", self.spec.class_name_for_type("string"))
        self.assertEqual("bool", self.spec.class_name_for_type("boolean"))


class TestInteger64JsonStrings(unittest.TestCase):
    def test_json_string_is_accepted(self):
        """R5 serializes integer64 as a JSON string; must not raise the
        `Wrong type <class 'str'>` error from issue #51."""
        att = FakeAttachment({"size": "12345"})
        self.assertEqual(12345, att.size)
        self.assertIsInstance(att.size, int)

    def test_json_number_still_works(self):
        att = FakeAttachment({"size": 42})
        self.assertEqual(42, att.size)

    def test_invalid_strings_still_rejected(self):
        for bad in ["12.5", "abc", "12a", "", "1_000", " 12", "0123"]:
            with self.assertRaises(FHIRValidationError, msg="value {!r}".format(bad)):
                FakeAttachment({"size": bad})

    def test_as_json_round_trip(self):
        att = FakeAttachment({"size": "99"})
        att2 = FakeAttachment(att.as_json())
        self.assertEqual(99, att2.size)


if __name__ == "__main__":
    unittest.main()
