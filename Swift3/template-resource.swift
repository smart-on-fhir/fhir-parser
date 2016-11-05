//
//  {{ profile.targetname }}.swift
//  SwiftFHIR
//
//  Generated from FHIR {{ info.version }} ({{ profile.url }}) on {{ info.date }}.
//  {{ info.year }}, SMART Health IT.
//

import Foundation
{% for klass in classes %}

/**
{{ klass.short|wordwrap(width=120, wrapstring="\n") }}.
{%- if klass.formal %}

{{ klass.formal|wordwrap(width=120, wrapstring="\n") }}
{%- endif %}
*/
open class {{ klass.name }}: {{ klass.superclass.name|default('FHIRAbstractBase') }} {
	{%- if klass.resource_name %}
	override open class var resourceType: String {
		get { return "{{ klass.resource_name }}" }
	}
	{% endif %}
	
	{%- for prop in klass.properties %}
	{%- if prop.enum %}
	/// {{ prop.formal|wordwrap(width=112, wrapstring="\n	/// ") }}
	{%- if prop.enum.restricted_to %}
	/// Only use: {{ prop.enum.restricted_to }}
	{%- endif %}
	{%- else %}
	/// {{ prop.short|wordwrap(width=112, wrapstring="\n	/// ") }}.
	{%- endif %}
	public var {{ prop.name }}: {% if prop.is_array %}[{% endif %}{{ prop.enum.name or prop.class_name }}{% if prop.is_array %}]{% endif %}?
	{% endfor -%}
	
	{% if klass.has_nonoptional %}
	
	/** Convenience initializer, taking all required properties as arguments. */
	public convenience init(
	{%- for nonop in klass.nonexpanded_properties %}{% if nonop.nonoptional %}
		{%- if past_first_item %}, {% endif -%}{% set past_first_item = True -%}
		{%- if nonop.one_of_many -%}
		{{ nonop.one_of_many }}: Any
		{%- else -%}
		{{ nonop.name }}: {% if nonop.is_array %}[{% endif %}{{ nonop.enum.name or nonop.class_name }}{% if nonop.is_array %}]{% endif %}
		{%- endif -%}
	{%- endif %}{% endfor -%}
	) {
		self.init()
	{%- for nonop in klass.nonexpanded_properties %}{% if nonop.nonoptional %}
		{%- if nonop.one_of_many %}{% for expanded in klass.expanded_nonoptionals[nonop.one_of_many] %}
		{% if past_first_item %}else {% endif -%}{% set past_first_item = True -%}
		if let value = {{ nonop.one_of_many }} as? {{ expanded.class_name }} {
			self.{{ expanded.name }} = value
		}
		{%- endfor %}
		else {
			fhir_warn("Type “\(type(of: {{ nonop.one_of_many }}))” for property “\({{ nonop.one_of_many }})” is invalid, ignoring")
		}
		{%- else %}
		self.{{ nonop.name }} = {{ nonop.name }}
		{%- endif %}
	{%- endif %}{% endfor %}
	}
	{% endif -%}
	
	{% if klass.properties %}
	
	override open func populate(from json: FHIRJSON, presentKeys: inout Set<String>) throws -> [FHIRValidationError]? {
		var errors = try super.populate(from: json, presentKeys: &presentKeys) ?? [FHIRValidationError]()
		{%- for prop in klass.properties %}
		if let exist = json["{{ prop.orig_name }}"] {
			presentKeys.insert("{{ prop.orig_name }}")
			if let val = exist as? {% if prop.is_array %}[{% endif %}{{ prop.json_class }}{% if prop.is_array %}]{% endif %} {
				{%- if prop.enum %}{% if prop.is_array %} var i = -1
				self.{{ prop.name }} = val.map() { i += 1
					if let enumval = {{ prop.enum.name }}(rawValue: $0) { return enumval }
					errors.append(FHIRValidationError(key: "{{ prop.name }}.\(i)", problem: "the value “\(val)” is not valid"))
					return nil
				}.filter() { nil != $0 }.map() { $0! }
				{%- else %}
				if let enumval = {{ prop.enum.name }}(rawValue: val) {
					self.{{ prop.name }} = enumval
				}
				else {
					errors.append(FHIRValidationError(key: "{{ prop.orig_name }}", problem: "the value “\(val)” is not valid"))
				}
				{%- endif %}
				{%- else %}{% if prop.class_name == prop.json_class %}
				self.{{ prop.name }} = val
				{%- else %}{% if prop.is_native %}{% if prop.is_array %}
				self.{{ prop.name }} = {{ prop.class_name }}.instantiate(fromArray: val)
				{%- else %}
				self.{{ prop.name }} = {{ prop.class_name }}({% if "String" == prop.json_class %}string{% else %}json{% endif %}: val)
				{%- endif %}{% else %}
				do {
					{%- if prop.is_array %}
					self.{{ prop.name }} = try {{ prop.class_name }}.instantiate(fromArray: val, owner: self) as? [{{ prop.class_name }}]
					{%- else %}{% if "Resource" == prop.class_name %}     {# The `Bundle` has generic resources #}
					self.{{ prop.name }} = try Resource.instantiate(from: val, owner: self) as? Resource
					{%- else %}
					self.{{ prop.name }} = try {{ prop.class_name }}(json: val, owner: self)
					{%- endif %}{% endif %}
				}
				catch let error as FHIRValidationError {
					errors.append(error.prefixed(with: "{{ prop.orig_name }}"))
				}
				{%- endif %}{% endif %}{% endif %}
			}
			else {
				errors.append(FHIRValidationError(key: "{{ prop.orig_name }}", wants: {% if prop.is_array %}Array<{% endif %}{{ prop.json_class }}{% if prop.is_array %}>{% endif %}.self, has: type(of: exist)))
			}
		}
		{%- if prop.nonoptional and not prop.one_of_many %}
		else {
			errors.append(FHIRValidationError(missing: "{{ prop.orig_name }}"))
		}
		{%- endif %}
		{%- endfor %}
		{%- if klass.expanded_nonoptionals %}
		
		// check if nonoptional expanded properties (i.e. at least one "answer" for "answer[x]") are present
		{%- for exp, props in klass.sorted_nonoptionals %}
		if {% for prop in props %}nil == self.{{ prop.name }}{% if not loop.last %} && {% endif %}{% endfor %} {
			errors.append(FHIRValidationError(missing: "{{ exp }}[x]"))
		}
		{%- endfor %}
		{%- endif %}
		return errors.isEmpty ? nil : errors
	}
	
	override open func asJSON(errors: inout [FHIRValidationError]) -> FHIRJSON {
		var json = super.asJSON(errors: &errors)
		{% for prop in klass.properties %}
		if let {{ prop.name }} = self.{{ prop.name }} {
		
		{%- if prop.is_array %}{% if prop.enum %}
			json["{{ prop.orig_name }}"] = {{ prop.name }}.map() { $0.rawValue }
		{%- else %}{% if prop.is_native %}
			json["{{ prop.orig_name }}"] = {{ prop.name }}.map() { $0.asJSON() }
		{%- else %}
			json["{{ prop.orig_name }}"] = {{ prop.name }}.map() { $0.asJSON(errors: &errors) }
		{%- endif %}{% endif %}
		
		{%- else %}{% if prop.enum %}
			json["{{ prop.orig_name }}"] = {{ prop.name }}.rawValue
		{%- else %}{% if prop.is_native %}
			json["{{ prop.orig_name }}"] = {{ prop.name }}.asJSON()
		{%- else %}
			json["{{ prop.orig_name }}"] = {{ prop.name }}.asJSON(errors: &errors)
		{%- endif %}{% endif %}{% endif %}
		}
		{%- else %}{% if prop.nonoptional %}
		else {
			// APPEND TO errors
		}
		{%- endif %}
		{%- endfor %}
		
		return json
	}
{%- endif %}
}
{% endfor %}

