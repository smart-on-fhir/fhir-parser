//
//  FHIRServer.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 01/24/15.
//  2015, SMART Health IT.
//

import Foundation


/// The FHIR server error domain.
public let FHIRServerErrorDomain = "FHIRServerError"


/**
    Struct to describe REST request types, with a convenience method to make a request FHIR compliant.
 */
public enum FHIRRequestType: String
{
	case GET = "GET"
	case PUT = "PUT"
	case POST = "POST"
	case DELETE = "DELETE"
	
	/** Prepare a given mutable URL request with appropriate headers, methods and body values. */
	func prepareRequest(req: NSMutableURLRequest, body: NSData? = nil) {
		req.HTTPMethod = rawValue
		req.setValue("UTF-8", forHTTPHeaderField: "Accept-Charset")
		
		switch self {
		case .GET:
			break
		case .PUT:
			req.HTTPBody = body
		case .POST:
			req.HTTPBody = body
		case .DELETE:
			break
		}
	}
}


/**
    Protocol for server objects to be used by `FHIRResource` and subclasses.
 */
public protocol FHIRServer
{
	/** A server object must always have a base URL. */
	var baseURL: NSURL { get }
	
	
	// MARK: - HTTP Request
	
	/*
	This method should first execute `handlerForRequestOfType()` to obtain an appropriate request handler, then execute the prepared
	request against the server.
	
	- param type: The type of the request (GET, PUT, POST or DELETE)
	- param path: The relative path on the server to be interacting against
	- param resource: The resource to be involved in the request, if any
	- param callback: A callback, likely called asynchronously, returning a response instance
	*/
	func performRequestOfType(type: FHIRRequestType, path: String, resource: FHIRResource?, callback: ((response: FHIRServerResponse) -> Void))
	
	
	// MARK: - Operations
	
	/**
	    Performs the given Operation.
	
	    The server should first validate the operation and only proceed with execution if validation succeeds.
	
	    `Resource` has extensions to facilitate working with operations, be sure to take a look.
	
	    - parameter operation: The operation instance to perform
	    - parameter callback: The callback to call when the request ends (success or failure)
	 */
	func performOperation(operation: FHIROperation, callback: ((response: FHIRServerResponse) -> Void))
}


/** Create an error in the FHIRServerErrorDomain error domain. */
func genServerError(message: String, code: Int = 0) -> NSError {
	return NSError(domain: FHIRServerErrorDomain, code: code, userInfo: [NSLocalizedDescriptionKey: message])
}

