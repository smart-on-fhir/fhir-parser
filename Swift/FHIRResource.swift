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
	/** If this instance was read from a server, this is the identifier that was used. */
	public var _localId: String?
	
	/** A specific version id, if the instance was created using `vread`. */
	public var _versionId: String?
	
	/** If this instance lives on a server, this property represents that server. */
	public var _server: FHIRServer?
	
	/** Human language of the content (BCP-47). */
	public var language: String?
	
	public required init(json: NSDictionary?) {
		super.init(json: json)
		if let js = json {
			if let val = js["language"] as? String {
				self.language = val
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
	 *  Reads the resource with the given id from the given server.
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
	 *  Reads the resource from the given path on the given server.
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
	
	public func search() -> FHIRSearchParam {
		if nil != _localId {
			return FHIRSearchParam(subject: "_id", reference: _localId!, type: self.dynamicType)
		}
		return FHIRSearchParam(profileType: self.dynamicType)
	}
	
	public class func search() -> FHIRSearchParam {
		return FHIRSearchParam(profileType: self)
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
	 *  Instance method that needs to take a path, which is relative to `baseURL`, retrieve data from that URL and
	 *  return a decoded NSDictionary or an error in a callback.
	 */
	func requestJSON(path: String, callback: ((json: NSDictionary?, error: NSError?) -> Void))
}

