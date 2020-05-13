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


for subclass in inheritors(FHIRAbstractResource):
    subclass.update_forward_refs()
