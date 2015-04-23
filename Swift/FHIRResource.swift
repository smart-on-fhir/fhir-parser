//
//  FHIRResource.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 7/2/14.
//  2014, SMART Health IT.
//

import Foundation


/**
 *  Abstract superclass for all FHIR resource models.
 */
public class FHIRResource: FHIRElement
{
	/// A specific version id, if the instance was created using `vread`.
	public var _versionId: String?
	
	/// If this instance lives on a server, this property represents that server.
	public var _server: FHIRServer? {
		get {
			return __server ?? owningResource()?._server
		}
		set {
			__server = newValue
		}
	}
	var __server: FHIRServer?
	
	/** Initialize with a JSON object. */
	public required init(json: FHIRJSON?) {
		super.init(json: json)
	}
	
	/** Serialize the receiver to JSON. */
	override public func asJSON() -> FHIRJSON {
		var json = super.asJSON()
		json["resourceType"] = self.dynamicType.resourceName
		
		return json
	}
	
	
	// MARK: - Printable
	
	override public var description: String {
		let nilstr = "nil"
		return "<\(self.dynamicType.resourceName)> \(id ?? nilstr) on \(__server?.baseURL ?? nilstr)"
	}
}

