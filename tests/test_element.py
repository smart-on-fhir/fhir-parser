import pytest
from fhirzeug.fhirspec import FHIRElementType

# R5
R5 = {
    "extension": [
        {
            "url": "http://hl7.org/fhir/StructureDefinition/structuredefinition-fhir-type",
            "valueUri": "string",
        }
    ],
    "code": "http://hl7.org/fhirpath/System.String",
}

# R4
R4 = {
    "extension": [
        {
            "url": "http://hl7.org/fhir/StructureDefinition/structuredefinition-fhir-type",
            "valueUrl": "string",
        }
    ],
    "code": "http://hl7.org/fhirpath/System.String",
}


@pytest.fixture(params=[R4, R5])
def element_type(request):
    return FHIRElementType(request.param)


def test_parse_from(element_type: FHIRElementType):
    print(element_type.profile)
    assert element_type.code == "string"
