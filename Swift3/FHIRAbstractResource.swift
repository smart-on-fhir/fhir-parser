//
//  FHIRAbstractResource.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 7/2/14.
//  2014, SMART Health IT.
//

import Foundation


/**
 *  Abstract superclass for all FHIR resource models.
 */
open class FHIRAbstractResource: FHIRAbstractBase {
	
	/// A specific version id, if the instance was created using `vread`.
	open var _versionId: String?
	
	/// If this instance lives on a server, this property represents that server.
	open var _server: FHIRServer? {
		get { return __server ?? owningResource?._server }
		set { __server = newValue }
	}
	var __server: FHIRServer?
	
	/** Initialize with a JSON object. */
	public required init(json: FHIRJSON?, owner: FHIRAbstractBase? = nil) {
		super.init(json: json, owner: owner)
	}
	
	/**
	The Resource, in contrast to the base element, definitely wants "resourceType" to be present. Will return an error complaining about it
	missing if it's not present.
	*/
	override open func populate(from json: FHIRJSON?, presentKeys: inout Set<String>) -> [FHIRJSONError]? {
		guard let json = json else {
			return nil
		}
		if let type = json["resourceType"] as? String {
			presentKeys.insert("resourceType")
			if type != type(of: self).resourceType {
				return [FHIRJSONError.init(key: "resourceType", problem: "should be “\(type(of: self).resourceType)” but is “\(type)”")]
			}
			return super.populate(from: json, presentKeys: &presentKeys)
		}
		return [FHIRJSONError(key: "resourceType")]
	}
	
	/** Serialize the receiver to JSON. */
	open override func asJSON() -> FHIRJSON {
		var json = super.asJSON()
		json["resourceType"] = type(of: self).resourceType
		
		return json
	}
	
	
	// MARK: - Printable
	
	override open var description: String {
		return "<\(type(of: self).resourceType)> \(__server?.baseURL.absoluteString ?? "nil")"
	}
}

