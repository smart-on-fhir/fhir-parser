//
//  CodeSystems.swift
//  SwiftFHIR
//
//  Generated from FHIR {{ info.version }} on {{ info.date }}.
//  {{ info.year }}, SMART Health IT.
//
{% for system in systems %}{% if system.generate_enum %}

/**
{{ system.definition.description|wordwrap(width=120, wrapstring="\n") }}

URL: {{ system.url }}
{%- if system.definition.valueSet %}
ValueSet: {{ system.definition.valueSet }}
{%- endif %}
*/
public enum {{ system.name }}: String {
	{%- for code in system.codes %}
	
	/// {{ code.definition|wordwrap(width=112, wrapstring="\n	/// ") }}
	case {{ code.name }} = "{{ code.code }}"
	{%- endfor %}
}
{% endif %}{% endfor %}

