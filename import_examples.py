import pathlib
import json

from pydantic.error_wrappers import ValidationError

import r4

for file_path in pathlib.Path("./downloads/httphl7orgfhirR4").glob("*-example.json"):
    print(file_path)
    with file_path.open() as f_in:
        doc = json.load(f_in)
        try:
            doc = r4.from_dict(doc)
            # print(doc.id)
        except ValidationError as er:
            print("...did not validate", er)
