//
//  FHIRContainedResource.swift
//  SMART-on-FHIR
//
//  Created by Pascal Pfiffner on 7/18/14.
//  2014, SMART Platforms.
//

import Foundation


/**
 *  Contained resources are stored to instances of this class until they are resolved.
 *  The id of contained resources will be appended to the hash sign (#) because they are usually referred to as URL
 *  fragment only. We'll have to see how this works or if we need to be more sophisticated.
 *
 *  http://hl7.org/implement/standards/fhir/references.html#contained
 */
public class FHIRContainedResource
{
	/** The id of the resource. */
	public var id: String?
	
	/** The type of the resource. */
	public var type: String?
	
	/** The complete JSON dictionary. */
	var json: NSDictionary?
	
	public init(id: String?, type: String?, json: NSDictionary?) {
		self.id = id
		self.type = type
		self.json = json
	}
	
	public convenience init(json: NSDictionary) {
		var id: String?
		if let jsonId = json["_id"] as? String {
			id = "#\(jsonId)"
		}
		let type = json["resourceType"] as? String
		self.init(id: id, type: type, json: json)
	}
}

