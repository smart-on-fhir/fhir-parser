//
//  {{ profile.targetname }}.swift
//  SMART-on-FHIR
//
//  Generated from FHIR {{ info.version }} ({{ profile.url }}) on {{ info.date }}.
//  {{ info.year }}, SMART Platforms.
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
public class {{ klass.name }}: {{ klass.superclass.name|default('FHIRElement') }}
{
{%- if klass.resource_name %}
	override public class var resourceName: String {
		get { return "{{ klass.resource_name }}" }
	}
{% endif -%}
	
{%- for prop in klass.properties %}	
	/// {{ prop.short|replace("\r\n", " ")|replace("\n", " ") }}
	public var {{ prop.name }}: {% if prop.is_array %}[{% endif %}{{ prop.class_name }}{% if prop.is_array %}]{% endif %}?
{% endfor -%}
{% if klass.has_nonoptional %}	
	public convenience init(
	{%- for nonop in klass.properties %}{% if nonop.nonoptional %}
		{%- if past_first_item %}, {% endif -%}
		{{ nonop.name }}: {% if nonop.is_array %}[{% endif %}{{ nonop.class_name }}{% if nonop.is_array %}]{% endif %}?
		{%- set past_first_item = True %}
	{%- endif %}{% endfor -%}
	) {
		self.init(json: nil)
	{%- for nonop in klass.properties %}{% if nonop.nonoptional %}
		if nil != {{ nonop.name }} {
			self.{{ nonop.name }} = {{ nonop.name }}
		}
	{%- endif %}{% endfor %}
	}
{% endif -%}
{% if klass.properties %}	
	public required init(json: JSONDictionary?) {
		super.init(json: json)
		if let js = json {
		{%- for prop in klass.properties %}
			if let val = js["{{ prop.orig_name }}"] as? {% if prop.is_array %}[{% endif %}{{ prop.json_class }}{% if prop.is_array %}]{% endif %} {
				{%- if prop.class_name == prop.json_class %}
				self.{{ prop.name }} = val
				{%- else %}
				
				{%- if prop.is_array %}{% if prop.is_native %}
				self.{{ prop.name }} = {{ prop.class_name }}.from(val)
				{%- else %}
				self.{{ prop.name }} = {{ prop.class_name }}.from(val, owner: self) as? [{{ prop.class_name }}]
				{%- endif %}
				
				{%- else %}{% if prop.is_native %}
				self.{{ prop.name }} = {{ prop.class_name }}({% if "String" == prop.json_class %}string{% else %}json{% endif %}: val)
				{%- else %}{% if "Resource" == prop.class_name %}
				self.{{ prop.name }} = Resource.instantiateFrom(val, owner: self) as? Resource
				{%- else %}
				self.{{ prop.name }} = {{ prop.class_name }}(json: val, owner: self)
				{%- endif %}{% endif %}{% endif %}{% endif %}
			}
		{%- endfor %}
		}
	}
	
	override public func asJSON() -> JSONDictionary {
		var json = super.asJSON()
		{% for prop in klass.properties %}
		{%- if prop.is_array %}{% if prop.is_native %}
		if let {{ prop.name }} = self.{{ prop.name }} {
			var arr = [AnyObject]()
			for val in {{ prop.name }} {
				arr.append(val.asJSON())
			}
			json["{{ prop.orig_name }}"] = arr
		}
		{%- else %}
		if let {{ prop.name }} = self.{{ prop.name }} {
			json["{{ prop.orig_name }}"] = {{ prop.class_name }}.asJSONArray({{ prop.name }})
		}
		{%- endif %}
		
		{%- else %}
		if let {{ prop.name }} = self.{{ prop.name }} {
			json["{{ prop.orig_name }}"] = {{ prop.name }}.asJSON()
		}
		{%- endif %}
		{%- endfor %}
		
		return json
	}
{%- endif %}
}
{% endfor %}

