//
//  FHIRElement+Factory.swift
//  SMART-on-FHIR
//
//  Generated from FHIR {{ info.version }} on {{ info.date }}.
//  {{ info.year }}, SMART Platforms.
//

import Foundation


/**
 *  Extension to FHIRElement to be able to instantiate by class name.
 */
extension FHIRElement
{
	public class func factory(className: String, json: NSDictionary, owner: FHIRElement?) -> FHIRElement {
		switch className {
		{%- for klass in classes %}{% if klass.resource_name %}
			case "{{ klass.resource_name }}":
				return {{ klass.name }}(json: json, owner: owner)
		{%- endif %}{% endfor %}
			default:
				return FHIRElement(json: json, owner: owner)
		}
	}
}

