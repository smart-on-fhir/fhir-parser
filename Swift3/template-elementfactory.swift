//
//  FHIRAbstractBase+Factory.swift
//  SwiftFHIR
//
//  Generated from FHIR {{ info.version }} on {{ info.date }}.
//  {{ info.year }}, SMART Health IT.
//


/**
Extension to FHIRAbstractBase to be able to instantiate by class name.
*/
extension FHIRAbstractBase {
	
	public class func factory(_ className: String, json: FHIRJSON, owner: FHIRAbstractBase?) throws -> FHIRAbstractBase {
		switch className {
		{%- for klass in classes %}{% if klass.resource_type %}
			case "{{ klass.resource_type }}":
				return try {{ klass.name }}(json: json, owner: owner)
		{%- endif %}{% endfor %}
			default:
				return try FHIRAbstractBase(json: json, owner: owner)
		}
	}
}

