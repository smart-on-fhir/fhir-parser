//
//  FHIRContainedResource.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 7/18/14.
//  2014, SMART Health IT.
//

import Foundation


/**
 *  Contained resources are stored to instances of this class until they are resolved.
 *
 *  The id of contained resources will be referenced from their parents as URL fragment, meaning "med1" will be
 *  referenced as "#med1".
 *
 *  http://hl7.org/implement/standards/fhir/references.html#contained
 */
public class FHIRContainedResource
{
	/// The id of the resource.
	public var id: String?
	
	/// The type of the resource.
	public var type: String?
	
	/// The complete JSON dictionary.
	var json: FHIRJSON?
	
	/// Contained resources always have an owner, the resource they are contained in.
	let owner: FHIRElement
	
	public init(id: String?, type: String?, json: FHIRJSON?, owner: FHIRElement) {
		self.id = id
		self.type = type
		self.json = json
		self.owner = owner
	}
	
	public convenience init(json: FHIRJSON, owner: FHIRElement) {
		let id = json["id"] as? String
		let type = json["resourceType"] as? String
		self.init(id: id, type: type, json: json, owner: owner)
	}
}

