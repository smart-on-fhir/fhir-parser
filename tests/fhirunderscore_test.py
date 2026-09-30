#!/usr/bin/env python
# -*- coding: utf-8 -*-
""" Regression tests for the last `Test R5` failure of
https://github.com/smart-on-fhir/fhir-parser/issues/51.

In FHIR JSON a primitive element may appear only through its
underscore-prefixed companion (e.g. `_questionnaire` carrying extensions
while the value itself is absent). The official R5 example
`questionnaireresponse-example-f201-lifelines.json` does exactly this, even
though `QuestionnaireResponse.questionnaire` is non-optional (min 1) in R5.
Such companions must satisfy the non-optional check at construction and
round-trip through `as_json()`.
"""

import os
import sys
import unittest

_HERE = os.path.dirname(os.path.abspath(__file__))
_REPO = os.path.dirname(_HERE)
for _p in (_REPO, os.path.join(_REPO, "Sample")):
    if _p not in sys.path:
        sys.path.insert(0, _p)

from fhirabstractbase import (                       # noqa: E402
    FHIRAbstractBase,
    FHIRValidationError,
)


class FakeQuestionnaireResponse(FHIRAbstractBase):
    """Stands in for the generated R5 `QuestionnaireResponse`: `questionnaire`
    is declared non-optional, like the real R5 model."""

    def __init__(self, jsondict=None, strict=True):
        self.questionnaire = None
        self.status = None
        super(FakeQuestionnaireResponse, self).__init__(jsondict, strict)

    def elementProperties(self):
        js = super(FakeQuestionnaireResponse, self).elementProperties()
        js.extend([
            ("questionnaire", "questionnaire", str, False, None, True),
            ("status", "status", str, False, None, True),
        ])
        return js


COMPANION = {
    "extension": [{
        "url": "http://hl7.org/fhir/StructureDefinition/display",
        "valueString": "Lifelines",
    }]
}


class TestUnderscoreCompanion(unittest.TestCase):
    def test_companion_only_satisfies_non_optional(self):
        """Mirrors the official R5 example: no `questionnaire` value, only
        `_questionnaire` with extensions."""
        inst = FakeQuestionnaireResponse({
            "status": "in-progress",
            "_questionnaire": COMPANION,
        })
        self.assertIsNone(inst.questionnaire)

    def test_companion_round_trips_through_as_json(self):
        inst = FakeQuestionnaireResponse({
            "status": "in-progress",
            "_questionnaire": COMPANION,
        })
        js = inst.as_json()
        self.assertEqual(COMPANION, js["_questionnaire"])
        inst2 = FakeQuestionnaireResponse(js)
        self.assertEqual(COMPANION, inst2.as_json()["_questionnaire"])

    def test_truly_missing_still_rejected(self):
        with self.assertRaises(FHIRValidationError):
            FakeQuestionnaireResponse({"status": "in-progress"})
        # as_json must still fail once the companion is dropped
        inst = FakeQuestionnaireResponse({
            "status": "in-progress",
            "_questionnaire": COMPANION,
        })
        del inst._primitive_companions["_questionnaire"]
        with self.assertRaises(FHIRValidationError):
            inst.as_json()

    def test_normal_value_still_works(self):
        inst = FakeQuestionnaireResponse({
            "questionnaire": "Questionnaire/123",
            "status": "in-progress",
        })
        self.assertEqual("Questionnaire/123", inst.as_json()["questionnaire"])


if __name__ == "__main__":
    unittest.main()
