{#  We will include the FHIRSearchElement.py class file first, then generate all
    search params and append them to the end of the class as methods. This will
    generate one big class with all valid search parameters. #}

{%- include "Python/FHIRSearchElement.py" %}
    
    # MARK: Generated Methods
    {% for ext in extensions %}
    def {{ ext.name }}(self, {{ ext.type }}):
        """ Perform a search for "{{ ext.original }}" {{ ext.type }}. """
        p = FHIRSearchElement(subject="{{ ext.original }}")
        p.{{ ext.type }} = {{ ext.type }}
        {%- if "_" != ext.name[0] %}
        {%- if ext.name in in_profiles %}
        p.supported_profiles = [
        {%- for prof in in_profiles[ext.name]|sort %}
            "{{ prof }}"
            {%- if not loop.last %},{% endif -%}
        {%- endfor %}
        ]
        {%- endif %}
        {%- endif %}
        p.previous = self
        return p
    
    {%- if "token" == ext.type %}
    
    def {{ ext.name }}_as_text(self, token):
        """ Perform a fulltext search for token "{{ ext.original }}". """
        p = FHIRSearchElement(subject="{{ ext.original }}")
        p.token = token
        p.token_as_text = True
        p.previous = self
        return p
    
    {%- else %}
    {%- if "string" == ext.type %}
    
    def {{ ext.name }}_exact(self, string):
        """ Search for an exact match for "{{ ext.original }}". """
        p = FHIRSearchElement(subject="{{ ext.original }}")
        p.string = string
        p.string_exact = True
        p.previous = self
        return p
    
    {%- endif %}{% endif %}
    {%- if "_" != ext.name[0] and (ext.name not in dupes or "string" == ext.type) %}
    
    def {{ ext.name }}_missing(self, flag):
        """ Specify if "{{ ext.original }}" should be missing or not. """
        p = FHIRSearchElement(subject="{{ ext.original }}")
        p.missing = flag
        p.previous = self
        return p
    
    {%- endif %}
    {% endfor %}


# some tests, to be removed after development phase
if '__main__' == __name__:
    from patient import Patient
    print('1 '+Patient.where().name("Willis").name_exact("Bruce").construct())
    print('= Patient?name=Willis&name:exact=Bruce')
    print('')
    print('2 '+Patient.where().address("Boston").gender('male').given_exact("Willis").construct())
    print('= Patient?address=Boston&gender=male&given:exact=Willis')

