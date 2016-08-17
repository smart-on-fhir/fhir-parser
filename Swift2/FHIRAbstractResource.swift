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
public class FHIRAbstractResource: FHIRAbstractBase {
	
	/// A specific version id, if the instance was created using `vread`.
	public var _versionId: String?
	
	/// If this instance lives on a server, this property represents that server.
	public var _server: FHIRServer? {
		get { return __server ?? owningResource()?._server }
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
	public override func populateFromJSON(json: FHIRJSON?, inout presentKeys: Set<String>) -> [FHIRJSONError]? {
		guard let json = json else {
			return nil
		}
		if let type = json["resourceType"] as? String {
			presentKeys.insert("resourceType")
			if type != self.dynamicType.resourceName {
				return [FHIRJSONError.init(key: "resourceType", problem: "should be “\(self.dynamicType.resourceName)” but is “\(type)”")]
			}
			return super.populateFromJSON(json, presentKeys: &presentKeys)
		}
		return [FHIRJSONError(key: "resourceType")]
	}
	
	/** Serialize the receiver to JSON. */
	public override func asJSON() -> FHIRJSON {
		var json = super.asJSON()
		json["resourceType"] = self.dynamicType.resourceName
		
		return json
	}
	
	
	// MARK: - Printable
	
	override public var description: String {
		return "<\(self.dynamicType.resourceName)> \(__server?.baseURL.absoluteString ?? "nil")"
	}
}

