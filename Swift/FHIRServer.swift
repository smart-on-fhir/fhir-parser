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
		req.setValue("application/json+fhir", forHTTPHeaderField: "Accept")
		req.setValue("UTF-8", forHTTPHeaderField: "Accept-Charset")
		
		switch self {
		case .GET:
			break
		case .PUT:
			req.setValue("application/json+fhir; charset=utf-8", forHTTPHeaderField: "Content-Type")
			req.HTTPBody = body
		case .POST:
			req.setValue("application/json+fhir; charset=utf-8", forHTTPHeaderField: "Content-Type")
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
	
	/**
	    Performs an HTTP request against a relative path on the receiver.
	
	    The supplied request handler can provide request body data, depending on which class it is, and also determines the type of
	    response and how response data is handled.
	
	    This method is being called from the REST extension on `Resource`, with a JSON request handler and therefore expected to deliver a
	    JSON response.
	
	    - parameter path: The REST path to request, relative to the server's base URL
	    - parameter handler: The FHIRServerRequestHandler instance informing NSURLRequest creation
	    - parameter callback: The callback to call when the request ends (success or failure)
	 */
	func performRequestAgainst<R: FHIRServerRequestHandler>(path: String, handler: R, callback: ((response: R.ResponseType) -> Void))
	
	
	// MARK: - Operations
	
	/**
	    Performs the given Operation.
	
	    The server should first validate the operation and only proceed with execution if validation succeeds.
	
	    `Resource` has extensions to facilitate working with operations, be sure to take a look.
	
	    - parameter operation: The operation instance to perform
	    - parameter callback: The callback to call when the request ends (success or failure)
	 */
	func performOperation(operation: FHIROperation, callback: ((response: FHIRServerJSONResponse) -> Void))
}


/** Create an error in the FHIRServerErrorDomain error domain. */
func genServerError(message: String, code: Int = 0) -> NSError {
	return NSError(domain: FHIRServerErrorDomain, code: code, userInfo: [NSLocalizedDescriptionKey: message])
}

