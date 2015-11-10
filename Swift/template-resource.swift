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
{% endfor %}	
	
	/** Initialize with a JSON object. */
	public required init(json: FHIRJSON?) {
		super.init(json: json)
	}
{% if klass.has_nonoptional %}	
	/** Convenience initializer, taking all required properties as arguments. */
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
	{% if False %}
	override func populateFromJSON(json: FHIRJSON?, inout presentKeys: Set<String>) -> [FHIRJSONError]? {
		var errors = super.populateFromJSON(json, presentKeys: &presentKeys) ?? [FHIRJSONError]()
		if let js = json {
		{%- for prop in klass.properties %}
			if let exist: AnyObject = js["{{ prop.orig_name }}"] {
				presentKeys.insert("{{ prop.orig_name }}")
				if let val = exist as? {% if prop.is_array %}[{% endif %}{{ prop.json_class }}{% if prop.is_array %}]{% endif %} {
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
				else {
					errors.append(FHIRJSONError(key: "{{ prop.orig_name }}", wants: {% if prop.is_array %}[{% endif %}{{ prop.json_class }}{% if prop.is_array %}]{% endif %}.self, has: exist.dynamicType))
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
			{%- for exp, props in klass.expanded_nonoptionals.items() %}
			if {% for prop in props %}nil == self.{{ prop.name }}{% if not loop.last %} && {% endif %}{% endfor %} {
				errors.append(FHIRJSONError(key: "{{ exp }}*"))
			}
			{%- endfor %}
		{%- endif %}
		}
		return errors.isEmpty ? nil : errors
	}
	
	override public func asJSON() -> FHIRJSON {
		var json = super.asJSON()
		{% for prop in klass.properties %}
		if let {{ prop.name }} = self.{{ prop.name }} {
		
		{%- if prop.is_array %}{% if prop.is_native %}
			var arr = [AnyObject]()
			for val in {{ prop.name }} {
				arr.append(val.asJSON())
			}
			json["{{ prop.orig_name }}"] = arr
		
		{%- else %}
			json["{{ prop.orig_name }}"] = {{ prop.class_name }}.asJSONArray({{ prop.name }})
		{%- endif %}
		
		{%- else %}
			json["{{ prop.orig_name }}"] = {{ prop.name }}.asJSON()
		{%- endif %}
		}
		{%- endfor %}
		
		return json
	}
	{% endif %}
	
	
	// MARK: - Properties
	
	override public subscript(name: String) -> FHIRJSONConvertible? {
		get {
			switch name {
			{%- for prop in klass.properties %}
			case "{{ prop.orig_name }}":
				return self.{{ prop.name }}?.asJSON()
			{%- endfor %}
			default:
				return super[name]
			}
		}
		set(newValue) {
			switch name {
			{%- for prop in klass.properties %}
			case "{{ prop.orig_name }}":
				{%- set full_json_class -%}
					{% if prop.is_array %}[{% endif %}{{ prop.json_class }}{% if prop.is_array %}]{% endif %}
				{%- endset %}
				{%- set forced_json_class -%}
					(val as! {{ full_json_class }})
				{%- endset %}
				guard let val = newValue where val is {{ full_json_class }} else {
					_lastSubscriptSetterError = FHIRJSONError(key: "{{ prop.orig_name }}", wants: {{ full_json_class }}.self, has: newValue.dynamicType)
					self.{{ prop.name }} = nil
					return
				}
								
				{%- if prop.class_name == prop.json_class %}		{# String, Int, Bool #}
				self.{{ prop.name }} = {{ forced_json_class }}
				{%- else %}
				
				{%- if prop.is_array %}{% if prop.is_native %}
				self.{{ prop.name }} = {{ prop.class_name }}.from({{ forced_json_class }})
				{%- else %}
				self.{{ prop.name }} = {{ prop.class_name }}.from({{ forced_json_class }}, owner: self) as? [{{ prop.class_name }}]
				{%- endif %}
				
				{%- else %}{% if prop.is_native %}
				self.{{ prop.name }} = {{ prop.class_name }}({% if "String" == prop.json_class %}string{% else %}json{% endif %}: {{ forced_json_class }})
				{%- else %}{% if "Resource" == prop.class_name %}
				self.{{ prop.name }} = Resource.instantiateFrom({{ forced_json_class }}, owner: self) as? Resource
				{%- else %}
				self.{{ prop.name }} = {{ prop.class_name }}(json: {{ forced_json_class }}, owner: self)
				{%- endif %}{% endif %}{% endif %}{% endif %}
			{%- endfor %}
			default:
				super[name] = newValue
			}
		}
	}
	
	override public func elementProperties() -> [FHIRElementPropertyDefn] {
		let mine: [FHIRElementPropertyDefn] = [
		{%- for prop in klass.properties %}
			FHIRElementPropertyDefn(name: "{{ prop.name }}", jsonName: "{{ prop.orig_name }}", type: {% if prop.is_array %}[{% endif %}{{ prop.class_name }}{% if prop.is_array %}]{% endif %}.self, isArray: {% if prop.is_array %}true{% else %}false{% endif %}, mandatory: {% if prop.nonoptional %}true{% else %}false{% endif %}, oneOfMany: {% if prop.one_of_many %}"{{ prop.one_of_many|replace('[x]', '') }}"{% else %}nil{% endif %}),
		{%- endfor %}
		]
		var elements = super.elementProperties()
		elements.appendContentsOf(mine)
		return elements
	}
{%- endif %}
}
{% endfor %}

