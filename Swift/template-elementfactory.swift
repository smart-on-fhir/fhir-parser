//
//  FHIRElement+Factory.swift
//  SMART-on-FHIR
//
//  Generated from FHIR {{ info.version }} on {{ info.date }}.
//  Copyright (c) {{ info.year }} SMART Platforms. All rights reserved.
//

import Foundation


/**
 *  Extension to FHIRElement to be able to instantiate by class name.
 */
extension FHIRElement
{
	public class func factory(className: String, json: NSDictionary) -> FHIRElement {
		switch className {
		{%- for klass in classes|sort %}
			case "{{ klass }}":	return {{ klass }}(json: json)
		{%- endfor %}
			default:	return FHIRElement(json: json)
		}
	}
}

