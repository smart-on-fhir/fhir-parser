//
//  FHIRPrimitive.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 06.12.16.
//  2016, SMART Health IT.
//

import Foundation


public protocol FHIRPrimitive {
	
	/// An optional id of the element.
	var id: String? { get set }
	
	/// The parent/owner of the receiver, if any. Used to dereference resources.
	weak var _owner: FHIRAbstractBase? { get set }
	
	/// Optional extensions of the element.
	var extension_fhir: [Extension]? { get set }
	
	/**
	Used during parsing, applies the values found in `json` (id and extension) to the receiver and returns the updated receiver.
	
	- parameter json: The JSON dictionary to use to update the receiver
	- returns:        A copy of the receiver or simply `self`
	*/
	func updatedWith(json: FHIRJSON) throws -> Self
}


extension FHIRPrimitive {
	
	public func updatedWith(json: FHIRJSON) throws -> Self {
		var copy = self
		if let id = json["id"] as? String {
			copy.id = id
		}
		if let val = json["extension"] as? [FHIRJSON] {
			copy.extension_fhir = try Extension.instantiate(fromArray: val, owner: _owner) as? [Extension]
		}
		return copy
	}
}

