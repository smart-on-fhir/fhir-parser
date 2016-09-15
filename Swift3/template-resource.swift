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
 *  {{ klass.short|wordwrap(width=116, wrapstring="\n *  ") }}.
{%- if klass.formal %}
 *
 *  {{ klass.formal|wordwrap(width=116, wrapstring="\n *  ") }}
{%- endif %}
 */
open class {{ klass.name }}: {{ klass.superclass.name|default('FHIRAbstractBase') }} {
{%- if klass.resource_name %}
	override open class var resourceType: String {
		get { return "{{ klass.resource_name }}" }
	}
{% endif -%}
	
{%- for prop in klass.properties %}	
	/// {{ prop.short|replace("\r\n", " ")|replace("\n", " ") }}.
	public var {{ prop.name }}: {% if prop.is_array %}[{% endif %}{{ prop.class_name }}{% if prop.is_array %}]{% endif %}?
{% endfor %}	
	
	/** Initialize with a JSON object. */
	public required init(json: FHIRJSON?, owner: FHIRAbstractBase? = nil) {
		super.init(json: json, owner: owner)
	}
{% if klass.has_nonoptional %}	
	/** Convenience initializer, taking all required properties as arguments. */
	public convenience init(
	{%- for nonop in klass.properties %}{% if nonop.nonoptional %}
		{%- if past_first_item %}, {% endif -%}
		{{ nonop.name }}: {% if nonop.is_array %}[{% endif %}{{ nonop.class_name }}{% if nonop.is_array %}]{% endif %}
		{%- set past_first_item = True %}
	{%- endif %}{% endfor -%}
	) {
		self.init(json: nil)
	{%- for nonop in klass.properties %}{% if nonop.nonoptional %}
		self.{{ nonop.name }} = {{ nonop.name }}
	{%- endif %}{% endfor %}
	}
{% endif -%}
{% if klass.properties %}	
	override open func populate(from json: FHIRJSON?, presentKeys: inout Set<String>) -> [FHIRJSONError]? {
		var errors = super.populate(from: json, presentKeys: &presentKeys) ?? [FHIRJSONError]()
		if let js = json {
		{%- for prop in klass.properties %}
			if let exist = js["{{ prop.orig_name }}"] {
				presentKeys.insert("{{ prop.orig_name }}")
				if let val = exist as? {% if prop.is_array %}[{% endif %}{{ prop.json_class }}{% if prop.is_array %}]{% endif %} {
					{%- if prop.class_name == prop.json_class %}
					self.{{ prop.name }} = val
					{%- else %}
					
					{%- if prop.is_array %}{% if prop.is_native or 'FHIRElement' == prop.class_name %}
					self.{{ prop.name }} = {{ prop.class_name }}.instantiate(fromArray: val)
					{%- else %}
					self.{{ prop.name }} = {{ prop.class_name }}.instantiate(fromArray: val, owner: self) as? [{{ prop.class_name }}]
					{%- endif %}
					
					{%- else %}{% if prop.is_native %}
					self.{{ prop.name }} = {{ prop.class_name }}({% if "String" == prop.json_class %}string{% else %}json{% endif %}: val)
					{%- else %}{% if "Resource" == prop.class_name %}
					self.{{ prop.name }} = Resource.instantiate(from: val, owner: self) as? Resource
					{%- else %}
					self.{{ prop.name }} = {{ prop.class_name }}(json: val, owner: self)
					{%- endif %}{% endif %}{% endif %}{% endif %}
				}
				else {
					errors.append(FHIRJSONError(key: "{{ prop.orig_name }}", wants: {% if prop.is_array %}Array<{% endif %}{{ prop.json_class }}{% if prop.is_array %}>{% endif %}.self, has: type(of: exist)))
				}
			}
			{%- if prop.nonoptional and not prop.one_of_many %}
			else {
				errors.append(FHIRJSONError(key: "{{ prop.orig_name }}"))
			}
			{%- endif %}
		{%- endfor %}
		{%- if klass.expanded_nonoptionals %}
			
			// check if nonoptional expanded properties are present
			{%- for exp, props in klass.sorted_nonoptionals %}
			if {% for prop in props %}nil == self.{{ prop.name }}{% if not loop.last %} && {% endif %}{% endfor %} {
				errors.append(FHIRJSONError(key: "{{ exp }}*"))
			}
			{%- endfor %}
		{%- endif %}
		}
		return errors.isEmpty ? nil : errors
	}
	
	override open func asJSON() -> FHIRJSON {
		var json = super.asJSON()
		{% for prop in klass.properties %}
		if let {{ prop.name }} = self.{{ prop.name }} {
		
		{%- if prop.is_array %}{% if prop.is_native %}
			var arr = [Any]()
			for val in {{ prop.name }} {
				arr.append(val.asJSON())
			}
			json["{{ prop.orig_name }}"] = arr
		
		{%- else %}
			json["{{ prop.orig_name }}"] = {{ prop.name }}.map() { $0.asJSON() }
		{%- endif %}
		
		{%- else %}
			json["{{ prop.orig_name }}"] = {{ prop.name }}.asJSON()
		{%- endif %}
		}
		{%- endfor %}
		
		return json
	}
{%- endif %}
}
{% endfor %}

