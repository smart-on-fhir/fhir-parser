"""Generated from FHIR 4.0.1-9346c8cc45 (http://hl7.org/fhir/StructureDefinition/Element) on 2020-05-04.
2020, Skalar Systems, BlackTusk.
"""


from . import fhirabstractbase


# <FHIRClass> path: FHIRAbstractBase, name: FHIRAbstractBase, resourceType: None
from .fhirabstractbase import FHIRAbstractBase


class Element(fhirabstractbase.FHIRAbstractBase):
    """Base for all elements.
    
    Base definition for all elements in a resource.
    """

    id: str
    """ Unique id for inter-element referencing.
    Type `str`. """

    extension: "Extension"
    """ Additional content defined by implementations.
    List of `Extension` items (represented as `dict` in JSON). """


# <FHIRClass> path: Extension, name: Extension, resourceType: None
from .extension import Extension
