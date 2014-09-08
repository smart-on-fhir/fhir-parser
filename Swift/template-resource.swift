//
//  {{ info.main }}.swift
//  SMART-on-FHIR
//
//  Generated from FHIR {{ info.version }} ({{ info.filename }}) on {{ info.date }}.
//  Copyright (c) {{ info.year }} SMART Platforms. All rights reserved.
//

import Foundation
{% for klass in classes %}

/**
 *  {{ klass.short|replace("\n", "\n *  ") }}.
{%- if klass.formal %}
 *
 *  {{ klass.formal|replace("\n", "\n *  ") }}
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
	/** {{ prop.short }} */
	{%- if prop.isReferenceTo %}
	public var {{ prop.name }}: {% if prop.isArray %}[{% endif %}FHIRElement{% if prop.isArray %}]{% endif %}? {
		get { return resolveReference{% if prop.isArray %}s{% endif %}("{{ prop.name }}") }
		set {
			if nil != newValue {
				didSetReference{% if prop.isArray %}s{% endif %}(newValue!, name: "{{ prop.name }}")
			}
		}
	}
	{%- else %}
	public var {{ prop.name }}: {% if prop.isArray %}[{% endif %}{{ prop.className }}{% if prop.isArray %}]{% endif %}?
	{%- endif %}
{% endfor -%}
{% if klass.nonoptional|length > 0 %}	
	public convenience init(
	{%- for nonop in klass.nonoptional -%}
		{{ nonop.name }}: {% if nonop.isArray %}[{% endif %}{{ nonop.className }}{% if nonop.isArray %}]{% endif %}?
		{%- if not loop.last %}, {% endif -%}
	{%- endfor -%}
	) {
		self.init(json: nil)
	{%- for nonop in klass.nonoptional %}
		if nil != {{ nonop.name }} {
			self.{{ nonop.name }} = {{ nonop.name }}
		}
	{%- endfor %}
	}
{%- endif %}	
{% if klass.properties %}
	public required init(json: NSDictionary?) {
		super.init(json: json)
		if let js = json {
		{%- for prop in klass.properties %}
			if let val = js["{{ prop.name }}"] as? {% if prop.isArray %}[{% endif %}{{ prop.jsonClass }}{% if prop.isArray %}]{% endif %} {
				{%- if prop.isArray %}
				{%- if "String" == prop.className %}
				self.{{ prop.name }} = val
				{%- else %}
				self.{{ prop.name }} = {{ prop.className }}.from(val){% if "NS" != prop.className[:2] %} as? [{{ prop.className }}]{% endif %}
				{%- endif %}
				{%- else %}{% if prop.className == prop.jsonClass %}
				self.{{ prop.name }} = val
				{%- else %}{% if "Int" == prop.jsonClass %}
				self.{{ prop.name }} = (1 == val)
				{%- else %}
				self.{{ prop.name }} = {{ prop.className }}({% if "Double" != prop.className %}json: {% endif %}val)
				{%- endif %}{% endif %}{% endif %}
			}
		{%- endfor %}
		}
	}
{%- endif %}
}
{% endfor %}

