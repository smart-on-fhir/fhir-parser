//
//  FHIRPrimitive.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 06.12.16.
//  2016, SMART Health IT.
//

import Foundation


public protocol FHIRPrimitive: FHIRJSONType {
	
	/// An optional id of the element.
	var id: String? { get set }
	
	/// Optional extensions of the element.
	var extension_fhir: [Extension]? { get set }
}

extension FHIRPrimitive {
	
	public mutating func populate(from json: FHIRJSON) throws {
		if let id = json["id"] as? String {
			self.id = id
		}
//		extension_fhir = instantiate(type: Extension.self, for: "extension", in: json, presentKeys: &presentKeys, errors: &errors, owner: _owner)
	}
}

