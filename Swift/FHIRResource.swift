//
//  FHIRResource.swift
//  SMART-on-FHIR
//
//  Created by Pascal Pfiffner on 7/2/14.
//  2014, SMART Platforms.
//

import Foundation


/// The block signature for server interaction callbacks that return an error.
public typealias FHIRErrorCallback = ((error: NSError?) -> Void)

/// The block signature for most server interaction callbacks that return a resource and an error.
public typealias FHIRResourceErrorCallback = ((resource: FHIRResource?, error: NSError?) -> Void)

/// The FHIR resource error domain
public let FHIRResourceErrorDomain = "FHIRResourceError"


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
	
	func owningResource() -> FHIRResource? {
		var owner = _owner
		while nil != owner {
			if nil != owner as? FHIRResource {
				break
			}
			owner = owner?._owner
		}
		return owner as? FHIRResource
	}
	
	public required init(json: JSONDictionary?) {
		super.init(json: json)
	}
	
	override public func asJSON() -> JSONDictionary {
		var json = super.asJSON()
		json["resourceType"] = self.dynamicType.resourceName
		
		return json
	}
	
	
	// MARK: - Retrieving Resources
	
	public func absoluteURI() -> NSURL? {
		if let myID = self.id {
			return _server?.baseURL.URLByAppendingPathComponent(self.dynamicType.resourceName).URLByAppendingPathComponent(myID)
		}
		return nil
	}
	
	/**
		Reads the resource with the given id from the given server.
	 */
	public class func read(id: String, server: FHIRServer, callback: FHIRResourceErrorCallback) {
		let path = "\(resourceName)/\(id)"
		readFrom(path, server: server, callback: callback)
	}
	
	/**
		Reads the resource from the given path on the given server.
	 */
	public class func readFrom(path: String, server: FHIRServer, callback: FHIRResourceErrorCallback) {
		server.getJSON(path) { response in
			if let error = response.error {
				callback(resource: nil, error: error)
			}
			else {
				let resource = self(json: response.body)
				resource._server = server
				callback(resource: resource, error: nil)
			}
		}
	}
	
	
	// MARK: - Sending Resources
	
	public func create(server: FHIRServer, callback: FHIRErrorCallback) {
		callback(error: genResourceError("Not implemented"))
	}
	
	public func update(callback: FHIRErrorCallback) {
		if let server = _server {
			if let id = self.id {
				server.putJSON("\(self.dynamicType.resourceName)/\(id)", body: asJSON()) { response in
					// should we do some header inspection (response.headers)?
					callback(error: response.error)
				}
			}
			else {
				callback(error: genResourceError("Cannot update a resource without id"))
			}
		}
		else {
			callback(error: genResourceError("Cannot update a resource that doesn't have a server"))
		}
	}
	
	
	// MARK: - Search
	
	public func search(query: AnyObject) -> FHIRSearch {
		if let myId = self.id {
			NSLog("UNFINISHED, must add '_id' reference to search expression")
			//return FHIRSearch(subject: "_id", reference: myId, type: self.dynamicType)
		}
		return FHIRSearch(type: self.dynamicType, query: query)
	}
	
	public class func search(query: AnyObject) -> FHIRSearch {
		return FHIRSearch(type: self, query: query)
	}
	
	
	// MARK: - Printable
	
	override public var description: String {
		return "<\(self.dynamicType.resourceName)> \(id) on \(__server?.baseURL)"
	}
}


/** Create an error in the FHIRResourceErrorDomain error domain. */
func genResourceError(message: String, code: Int = 0) -> NSError {
	return NSError(domain: FHIRResourceErrorDomain, code: code, userInfo: [NSLocalizedDescriptionKey: message])
}

