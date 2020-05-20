from fhirzeug.fhirspec import FHIRSpec
from fhirzeug.generators.python_pydantic.templates.resource_header import (
    choice_of_validator,
)
from pprint import pprint

import pytest

from pydantic import BaseModel, ValidationError, validator, root_validator
from typing import Optional


# the validator needs to be moved into a pydantic generator section


class X(BaseModel):

    a: Optional[str]
    b: Optional[str]
    c: Optional[str]

    x: int = 1

    _abc_choice_validator = root_validator(allow_reuse=True)(
        choice_of_validator({"a", "b", "c"}, False)
    )


class Y(BaseModel):

    a: Optional[str]
    b: Optional[str]
    c: Optional[str]

    x: int = 1

    _abc_choice_validator = root_validator(allow_reuse=True)(
        choice_of_validator({"a", "b", "c"}, True)
    )


@pytest.mark.parametrize(
    "cls,is_ok,data",
    [
        (X, True, {"a": "Hello"}),
        (X, True, {"b": "Hello"}),
        (X, False, {},),
        (X, False, {"b": "Hello", "c": "World"}),
        (Y, True, {"a": "Hello"}),
        (Y, True, {"b": "Hello"}),
        (Y, True, {},),
        (Y, False, {"b": "Hello", "c": "World"}),
    ],
)
def test_pydantic_model(cls, is_ok, data):
    """This tests if the function which is used in the template would work"""

    if not is_ok:
        with pytest.raises(ValidationError):
            cls(**data)
    else:
        cls(**data)
