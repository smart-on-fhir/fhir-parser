from py_pydantic.element import Element
from py_pydantic.extension import Extension

Element.update_forward_refs()

e = Element(id="bla")


print(e.dict(exclude_unset=True))
