//
//  FHIRServer.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 01/24/15.
//  2015, SMART Health IT.
//

import Foundation


/**
    Struct to describe REST request types, with a convenience method to make a request FHIR compliant.
 */
public enum FHIRRequestType: String {
	case GET = "GET"
	case PUT = "PUT"
	case POST = "POST"
	case PATCH = "PATCH"
	case DELETE = "DELETE"
	case OPTIONS = "OPTIONS"
	
	/** Prepare a given mutable URL request with appropriate headers, methods and body values. */
	public func prepareRequest(req: NSMutableURLRequest, body: NSData? = nil) {
		req.HTTPMethod = rawValue
		req.setValue("UTF-8", forHTTPHeaderField: "Accept-Charset")
		
		switch self {
		case .GET:
			break
		case .PUT:
			req.HTTPBody = body
		case .POST:
			req.HTTPBody = body
		case .PATCH:
			req.HTTPBody = body
		case .DELETE:
			break
		case .OPTIONS:
			break
		}
	}
}


/**
    Protocol for server objects to be used by `FHIRResource` and subclasses.
 */
public protocol FHIRServer {
	
	/** A server object must always have a base URL. */
	var baseURL: NSURL { get }
	
	/** Designated initializer. */
	init(baseURL base: NSURL, auth: [String: AnyObject]?)
	
	
	// MARK: - HTTP Request
	
	/*
	Execute a request of given type against the given path, which is relative to the receiver's `baseURL`, with the given resource (if any).
	
	- parameter type: The type of the request (GET, PUT, POST or DELETE)
	- parameter path: The relative path on the server to be interacting against
	- parameter resource: The resource to be involved in the request, if any
	- parameter callback: A callback, likely called asynchronously, returning a response instance
	*/
	func performRequestOfType(type: FHIRRequestType, path: String, resource: Resource?, callback: ((response: FHIRServerResponse) -> Void))
}

