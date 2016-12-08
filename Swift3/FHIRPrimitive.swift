//
//  FHIRPrimitive.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 06.12.16.
//  2016, SMART Health IT.
//

import Foundation


public protocol FHIRPrimitive: FHIRJSONType {
	
	/// An optional id of the element. This is not a FHIRString as it segfaults the Swift 3.0.1 compiler.
	var id: String? { get set }
	
	/// Optional extensions of the element.
	var extension_fhir: [Extension]? { get set }
}

extension FHIRPrimitive {
	
	/**
	Default implementation to perform JSON parsing on primitives.
	 
	- parameter json:        The JSON element to use to populate the receiver
	- parameter presentKeys: An in-out parameter being filled with key names used.
	- returns:               An optional array of errors reporting missing mandatory keys or keys containing values of the wrong type
	- throws:                If anything besides a `FHIRValidationError` happens
	*/
	public mutating func populate(from json: FHIRJSON, presentKeys: inout Set<String>) throws -> [FHIRValidationError]? {
		var errors = [FHIRValidationError]()
		if let id = json["id"] as? String {
			presentKeys.insert("id")
			self.id = id
		}
		extension_fhir = try createInstances(of: Extension.self, for: "extension", in: json, presentKeys: &presentKeys, errors: &errors, owner: _owner) ?? extension_fhir
		return errors.isEmpty ? nil : errors
	}
}

