//
//  {{ profile.targetname }}.swift
//  SwiftFHIR
//
//  Generated from FHIR {{ info.version }} ({{ profile.url }}) on {{ info.date }}.
//  {{ info.year }}, SMART Health IT.
//

import Foundation
import RealmSwift
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
	{% if prop.is_array -%}
		{%- if prop.is_primitive -%}
			public let {{ prop.name }} = RealmSwift.List<Realm{{ prop.class_name }}>()
		{%- elif prop.class_name -%}
			public let {{ prop.name }} = RealmSwift.List<{% if "Resource" == prop.class_name %}ContainedResource{%else%}{{ prop.class_name }}{%endif%}>()
		{%- endif -%}
	{%- else -%}
		{%- if prop.requires_realm_optional -%}
			public let {{ prop.name }} = RealmOptional<{{ prop.class_name }}>()		
		{%- else -%}		
			public dynamic var {{ prop.name }}: {{ prop.class_name }}?
		{%- endif %}
	{%- endif %}
	{# any resource with an ID requires a pk for Realm primary keys #}
	{%- if "id" == prop.name -%}
	public dynamic var pk = UUID().uuidString
	override open static func primaryKey() -> String? {
		return "pk"
	}
	{%- endif -%}
{% endfor %}

{% if klass.has_nonoptional %}	
	/** Convenience initializer, taking all required properties as arguments. */
	public convenience init(
	{%- for nonop in klass.properties|rejectattr("nonoptional", "equalto", false) %}
		{%- if loop.index is greaterthan 1 %}, {% endif -%}
		{%- if "value" == nonop.name %}val{% else %}{{ nonop.name }}{% endif %}: {% if nonop.is_array %}[{% endif %}{{ nonop.class_name }}{% if nonop.is_array %}]{% endif %}
	{%- endfor -%}
	) {
		self.init(json: nil)
	{%- for nonop in klass.properties %}{% if nonop.nonoptional %}
		{%- if nonop.is_array and nonop.is_native %}
		self.{{ nonop.name }}.append(objectsIn: {{ nonop.name }}.map{ Realm{{ nonop.class_name }}(value: [$0]) })
		{%- elif nonop.is_array %}
		self.{{ nonop.name }}.append(objectsIn: {{ nonop.name }})
		{%- else %}
		self.{{ nonop.name }}{% if nonop.requires_realm_optional %}.value{% endif %} = {% if "value" == nonop.name %}val{% else %}{{ nonop.name }}{% endif %}
		{%- endif %}
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
					{%- if prop.is_array and prop.is_native %}
					self.{{ prop.name }}.append(objectsIn: val.map{ Realm{{prop.class_name}}(value: [$0]) })
					{%- else %}
					self.{{ prop.name }}{% if prop.requires_realm_optional %}.value{% endif %} = val
					{# if we're inflating from a server JSON, we'll want to default the primaryKey to the same value as id #}
					{%- if prop.name == "id" %}self.pk = val{% endif %}
					{%- endif %}
					{%- else %}
					
					{%- if prop.is_array %}{% if prop.is_native or 'FHIRElement' == prop.class_name %}
					self.{{ prop.name }}.append(objectsIn: {{ prop.class_name }}.instantiate(fromArray: val))
					{%- elif 'Resource' == prop.class_name %}
					self.{{ prop.name }}.append(objectsIn: val.map({ return ContainedResource(json: $0, owner: self)}))
					{%- else %}
					if let vals = {{ prop.class_name }}.instantiate(fromArray: val, owner: self) as? [{{ prop.class_name }}] {
						self.{{ prop.name }}.append(objectsIn: vals)
					}					
					{%- endif %}
					
					{%- else %}{% if prop.is_native %}
					self.{{ prop.name }}{% if prop.requires_realm_optional %}.value{% endif %} = {{ prop.class_name }}({% if "String" == prop.json_class %}string{% else %}json{% endif %}: val)
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
			if {% for prop in props %}nil == self.{{ prop.name }}{% if prop.requires_realm_optional %}.value{% endif %}{% if not loop.last %} && {% endif %}{% endfor %} {
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
		{%- if prop.is_array %}
		if {{ prop.name }}.count > 0 {
			json["{{ prop.orig_name }}"] = Array({{ prop.name }}.map() { {% if prop.is_primitive %}$0.value{% else %}$0.asJSON(){% endif %} })
		}		
		{%- else %}
		if let {{ prop.name }} = self.{{ prop.name }}{% if prop.requires_realm_optional %}.value{% endif %} {
			json["{{ prop.orig_name }}"] = {{ prop.name }}.asJSON()
		}
		{%- endif -%}
		{%- endfor %}
		
		return json
	}
{%- endif %}
}
{% endfor %}

