{#  We will include the FHIRSearchParam.py class file first, then generate all
    search params and append it to the end of the class as methods. This will
    generate one big class with all valid search parameters. #}

{%- include "Python/FHIRSearchParam.py" %}
    
    # MARK: Generated Methods
    {% for ext in extensions %}
    def {{ ext.name }}(self, {{ ext.type }}):
        """ Perform a search for "{{ ext.original }}" {{ ext.type }}. """
        p = FHIRSearchParam(subject="{{ ext.original }}")
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
        p = FHIRSearchParam(subject="{{ ext.original }}")
        p.token = token
        p.token_as_text = True
        p.previous = self
        return p
    
    {%- else %}
    {%- if "string" == ext.type %}
    
    def {{ ext.name }}_exact(self, string):
        """ Search for an exact match for "{{ ext.original }}". """
        p = FHIRSearchParam(subject="{{ ext.original }}")
        p.string = string
        p.string_exact = True
        p.previous = self
        return p
    
    {%- endif %}{% endif %}
    {%- if "_" != ext.name[0] and (ext.name not in dupes or "string" == ext.type) %}
    
    def {{ ext.name }}_missing(self, flag):
        """ Specify if "{{ ext.original }}" should be missing or not. """
        p = FHIRSearchParam(subject="{{ ext.original }}")
        p.missing = flag
        p.previous = self
        return p
    
    {%- endif %}
    {% endfor %}

