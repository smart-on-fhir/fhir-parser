//
//  FHIRAbstractResource.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 7/2/14.
//  2014, SMART Health IT.
//

import Foundation


/**
Abstract superclass for all FHIR resource models.
*/
open class FHIRAbstractResource: FHIRAbstractBase {
	
	/// A specific version id, if the instance was created using `vread`.
	public var _versionId: String?
	
	/// If this instance lives on a server, this property represents that server.
	public var _server: FHIRServer? {
		get { return __server ?? owningResource?._server }
		set { __server = newValue }
	}
	var __server: FHIRServer?
	
	/**
	The Resource, in contrast to the base element, definitely wants "resourceType" to be present. Will return an error complaining about it
	missing if it's not present.
	*/
	override open func populate(from json: FHIRJSON, presentKeys: inout Set<String>) throws -> [FHIRValidationError]? {
		var errors = try super.populate(from: json, presentKeys: &presentKeys) ?? [FHIRValidationError]()
		if let type = json["resourceType"] as? String {
			presentKeys.insert("resourceType")
			if type != type(of: self).resourceType {
				errors.append(FHIRValidationError(key: "resourceType", problem: "should be “\(type(of: self).resourceType)” but is “\(type)”"))
			}
		}
		else {
			errors.append(FHIRValidationError(missing: "resourceType"))
		}
		return errors.isEmpty ? nil : errors
	}
	
	override open func decorate(json: inout FHIRJSON, errors: inout [FHIRValidationError]) {
		super.decorate(json: &json, errors: &errors)
		json["resourceType"] = type(of: self).resourceType
	}
	
	
	// MARK: - CustomStringConvertible
	
	override open var description: String {
		return "<\(type(of: self).resourceType)> \(__server?.baseURL.absoluteString ?? "nil")"
	}
}

