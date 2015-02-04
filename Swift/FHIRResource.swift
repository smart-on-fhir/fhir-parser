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
	
	/// Logical id of this artefact.
	public var id: String?
	
	/// Metadata about the resource.
	public var meta: FHIRResourceMeta?
	
	/// A set of rules under which this content was created.
	public var implicitRules: NSURL?
	
	/// Human language of the content (BCP-47).
	public var language: String?
	
	/// A human-readable narrative.
	public var text: Narrative?
	
	public required init(json: JSONDictionary?) {
		super.init(json: json)
		if let js = json {
			if let val = js["id"] as? String {
				id = val
			}
			if let val = js["meta"] as? JSONDictionary {
				meta = FHIRResourceMeta(json: val, owner: self)
			}
			if let val = js["implicitRules"] as? String {
				implicitRules = NSURL(json: val)
			}
			if let val = js["language"] as? String {
				language = val
			}
			if let val = js["text"] as? JSONDictionary {
				text = Narrative(json: val, owner: self)
			}
		}
	}
	
	override public func asJSON() -> JSONDictionary {
		var json = super.asJSON()
		json["resourceType"] = self.dynamicType.resourceName
		
		if let id = self.id {
			json["id"] = id
		}
		if let meta = self.meta {
			json["meta"] = meta.asJSON()
		}
		if let implicitRules = self.implicitRules {
			json["implicitRules"] = implicitRules.asJSON()
		}
		if let language = self.language {
			json["language"] = language
		}
		if let text = self.text {
			json["text"] = text.asJSON()
		}
		
		
		return json
	}
	
	
	// MARK: - Retrieving Resources
	
	public func absoluteURI() -> NSURL? {
		if let myID = id {
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
		if let myId = id {
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


/**
 *  Holds an element's metadata: http://hl7-fhir.github.io/resource.html#meta
 */
public class FHIRResourceMeta: FHIRElement
{
	/// Version specific identifier.
	public var versionId: String?
	
	/// When the resource version last changed.
	public var lastUpdated: Instant?
	
	/// Profiles this resource claims to conform to.
	public var profiles: [NSURL]?
	
	/// Security Labels applied to this resource.
	public var security: [Coding]?
	
	/// Tags applied.
	public var tags: [Coding]?
	
	public required init(json: JSONDictionary?) {
		super.init(json: json)
		if let js = json {
			if let val = js["versionId"] as? String {
				self.versionId = val
			}
			if let val = js["lastUpdated"] as? String {
				self.lastUpdated = Instant(string: val)
			}
			if let val = js["profiles"] as? [String] {
				self.profiles = NSURL.from(val)
			}
			if let val = js["security"] as? [JSONDictionary] {
				self.security = Coding.from(val) as? [Coding]
			}
			if let val = js["tags"] as? [JSONDictionary] {
				self.tags = Coding.from(val) as? [Coding]
			}
		}
	}
}


/** Create an error in the FHIRResourceErrorDomain error domain. */
func genResourceError(message: String, code: Int = 0) -> NSError {
	return NSError(domain: FHIRResourceErrorDomain, code: code, userInfo: [NSLocalizedDescriptionKey: message])
}

