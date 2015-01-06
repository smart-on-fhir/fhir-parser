//
//  FHIRResource.swift
//  SMART-on-FHIR
//
//  Created by Pascal Pfiffner on 7/2/14.
//  2014, SMART Platforms.
//

import Foundation


/**
 *  Abstract superclass for all FHIR resource models.
 */
public class FHIRResource: FHIRElement
{
	/// If this instance was read from a server, this is the identifier that was used, likely the same as `id`.
	public var _localId: String?
	
	/// A specific version id, if the instance was created using `vread`.
	public var _versionId: String?
	
	/// If this instance lives on a server, this property represents that server.
	public var _server: FHIRServer?
	
	/// Logical id of this artefact.
	public var id: String?
	
	/// Metadata about the resource.
	public var meta: FHIResourceMeta?
	
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
				meta = FHIResourceMeta(json: val, owner: self)
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
	
	
	// MARK: - Retrieving Resources
	
	public func absoluteURI() -> NSURL? {
		if nil != _localId {
			return _server?.baseURL.URLByAppendingPathComponent(self.dynamicType.resourceName).URLByAppendingPathComponent(_localId!)
		}
		return nil
	}
	
	/**
		Reads the resource with the given id from the given server.
	 */
	public class func read(id: String, server: FHIRServer, callback: ((resource: FHIRResource?, error: NSError?) -> ())) {
		let path = "\(resourceName)/\(id)"
		readFrom(path, server: server) { resource, error in
			if let res = resource {
				res._localId = id
			}
			callback(resource: resource, error: error)
		}
	}
	
	/**
		Reads the resource from the given path on the given server.
	 */
	public class func readFrom(path: String, server: FHIRServer, callback: ((resource: FHIRResource?, error: NSError?) -> ())) {
		server.requestJSON(path) { json, error in
			if nil != error {
				callback(resource: nil, error: error)
			}
			else {
				let resource = self(json: json)
				resource._server = server
				callback(resource: resource, error: nil)
			}
		}
	}
	
	
	// MARK: - Search
	
	public func search(query: AnyObject) -> FHIRSearch {
		if nil != _localId {
			NSLog("UNFINISHED, must add '_id' reference to search expression")
			//return FHIRSearch(subject: "_id", reference: _localId!, type: self.dynamicType)
		}
		return FHIRSearch(type: self.dynamicType, query: query)
	}
	
	public class func search(query: AnyObject) -> FHIRSearch {
		return FHIRSearch(type: self, query: query)
	}
}


/**
	Holds an element's metadata: http://hl7-fhir.github.io/resource.html#meta
 */
public class FHIResourceMeta: FHIRElement
{
	/// Version specific identifier.
	public var versionId: String?
	
	/// When the resource version last changed.
	public var lastUpdated: NSDate?
	
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
				self.lastUpdated = NSDate(json: val)
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


/**
 *  Protocol for server objects to be used by `FHIRResource` and subclasses.
 */
public protocol FHIRServer
{
	/** A server object must always have a base URL. */
	var baseURL: NSURL { get }
	
	/**
		Instance method that takes a path, which is relative to `baseURL`, retrieves data from that URL and returns a
		decoded JSONDictionary - or an error - in the callback.
	
		:param: path The REST path to request, relative to the server's base URL
		:param: callback The callback to call when the request ends (success or failure)
	 */
	func requestJSON(path: String, callback: ((json: JSONDictionary?, error: NSError?) -> Void))
}

