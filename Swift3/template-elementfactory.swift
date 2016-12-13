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
	
	public class func factory<T: FHIRAbstractBase>(_ typeName: String, json: FHIRJSON, owner: FHIRAbstractBase?, type: T.Type) throws -> T {
		switch typeName {
		{%- for klass in classes %}{% if klass.resource_type %}
			case "{{ klass.resource_type }}":
				if let res = try {{ klass.resource_type }}(json: json, owner: owner) as? T { return res }
		{%- endif %}{% endfor %}
			default:
				break
		}
		return try T(json: json, owner: owner)
	}
}

