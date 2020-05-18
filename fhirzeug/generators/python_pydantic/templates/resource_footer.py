def inheritors(klass):
    subclasses = set()
    work = [klass]
    while work:
        parent = work.pop()
        for child in parent.__subclasses__():
            if child not in subclasses:
                subclasses.add(child)
                work.append(child)
    return subclasses


for subclass in inheritors(FHIRAbstractBase):
    subclass.update_forward_refs()


RESOURCE_TYPE_MAP: typing.Dict[str, Resource] = {}
for subclass in inheritors(Resource):
    RESOURCE_TYPE_MAP[subclass.__name__] = subclass


def from_dict(dict_: dict):
    """Factory to load resources directly.
    
    The resources will be instaciated based on their resourceType property."""
    return RESOURCE_TYPE_MAP[dict_["resourceType"]](**dict_)
