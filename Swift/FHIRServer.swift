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
	
	/**
	Prepare a given mutable URL request with the respective method and body values.
	*/
	public func prepareRequest(req: NSMutableURLRequest, body: NSData? = nil) {
		req.HTTPMethod = rawValue
		
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
Struct to hold request headers. By default, the "Accept-Charset" header is set to "utf-8" upon initialization.
*/
public struct FHIRRequestHeaders {
	
	/// All the headers the instance is holding on to.
	public var headers: [FHIRRequestHeaderField: String]
	
	public init(_ headers: [FHIRRequestHeaderField: String]? = nil) {
		var hdrs = [FHIRRequestHeaderField.AcceptCharset: "utf-8"]
		headers?.forEach() { hdrs[$0] = $1 }
		self.headers = hdrs
	}
	
	public subscript(key: FHIRRequestHeaderField) -> String? {
		get { return headers[key] }
		set { headers[key] = newValue }
	}
	
	
	/**
	Prepare a given mutable URL request with the receiver's values.
	*/
	public func prepareRequest(req: NSMutableURLRequest) {
		headers.forEach {
			req.setValue($1, forHTTPHeaderField: $0.rawValue)
		}
	}
}


/**
Describe valid (and supported) FHIR request headers.

The "Authorization" header is not used in the basic library, it is provided for convenience's sake.
*/
public enum FHIRRequestHeaderField: String {
	case Accept          = "Accept"
	case AcceptCharset   = "Accept-Charset"
	case Authorization   = "Authorization"
	case ContentType     = "Content-Type"
	case Prefer          = "Prefer"
	case IfMatch         = "If-Match"
	case IfNoneMatch     = "If-None-Match"
	case IfModifiedSince = "If-Modified-Since"
	case IfNoneExist     = "If-None-Exist"
}


/**
Protocol for server objects to be used by `FHIRResource` and subclasses.
*/
public protocol FHIRServer {
	
	/** A server object must always have a base URL. */
	var baseURL: NSURL { get }
	
	/**
	Designated initializer. Should make sure that the base URL ends with a "/"!
	*/
	init(baseURL base: NSURL, auth: [String: AnyObject]?)
	
	
	// MARK: - HTTP Request
	
	/*
	Execute a request of given type against the given path, which is relative to the receiver's `baseURL`, with the given resource (if any).
	
	- parameter type:              The type of the request (GET, PUT, POST or DELETE)
	- parameter path:              The relative path on the server to be interacting against
	- parameter resource:          The resource to be involved in the request, if any
	- parameter additonalHeaders:  The headers to set on the request
	- parameter callback:          A callback, likely called asynchronously, returning a response instance
	*/
	func performRequestOfType(type: FHIRRequestType, path: String, resource: Resource?, additionalHeaders: FHIRRequestHeaders?, callback: ((response: FHIRServerResponse) -> Void))
}

