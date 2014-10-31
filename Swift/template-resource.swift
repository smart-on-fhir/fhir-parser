//
//  {{ info.main }}.swift
//  SMART-on-FHIR
//
//  Generated from FHIR {{ info.version }} ({{ info.filename }}) on {{ info.date }}.
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
public class {{ klass.className }}: {{ klass.superclass|default('FHIRElement') }}
{
{%- if klass.resourceName %}
	override public class var resourceName: String {
		get { return "{{ klass.resourceName }}" }
	}
{% endif -%}
	
{%- for prop in klass.properties %}	
	/// {{ prop.short|replace("\r\n", " ")|replace("\n", " ") }}
	public var {{ prop.name }}: {% if prop.isArray %}[{% endif %}{{ prop.className }}{% if prop.isReferenceTo %}<{{ prop.isReferenceTo }}>{% endif %}{% if prop.isArray %}]{% endif %}?
{% endfor -%}
{% if klass.hasNonoptional %}	
	public convenience init(
	{%- for nonop in klass.properties %}{% if nonop.nonoptional %}
		{%- if past_first_item %}, {% endif -%}
		{{ nonop.name }}: {% if nonop.isArray %}[{% endif %}{{ nonop.className }}{% if nonop.isReferenceTo %}<{{ nonop.isReferenceTo }}>{% endif %}{% if nonop.isArray %}]{% endif %}?
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
{%- endif %}	
{% if klass.properties %}
	public required init(json: NSDictionary?) {
		super.init(json: json)
		if let js = json {
		{%- for prop in klass.properties %}
			if let val = js["{{ prop.orig_name }}"] as? {% if prop.isArray %}[{% endif %}{{ prop.jsonClass }}{% if prop.isArray %}]{% endif %} {
				{%- if prop.isArray %}
				{%- if "String" == prop.className %}
				self.{{ prop.name }} = val
				{%- else %}{% if prop.isReferenceTo %}
				self.{{ prop.name }} = {{ prop.className }}.from(val, owner: self)
				{%- else %}
				self.{{ prop.name }} = {{ prop.className }}.from(val){% if "NS" != prop.className[:2] %} as? [{{ prop.className }}]{% endif %}
				{%- endif %}{% endif %}
				
				{%- else %}{% if prop.className == prop.jsonClass %}
				self.{{ prop.name }} = val
				{%- else %}{% if "Int" == prop.jsonClass %}
				self.{{ prop.name }} = (1 == val)
				{%- else %}{% if prop.isReferenceTo %}
				self.{{ prop.name }} = {{ prop.className }}(json: val, owner: self)
				{%- else %}
				self.{{ prop.name }} = {{ prop.className }}({% if "Double" != prop.className %}json: {% endif %}val)
				{%- endif %}{% endif %}{% endif %}{% endif %}
			}
		{%- endfor %}
		}
	}
{%- endif %}
}
{% endfor %}

