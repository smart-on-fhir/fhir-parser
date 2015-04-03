//
//  FHIRServer.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 01/24/15.
//  2015, SMART Health IT.
//

import Foundation


/**
	Protocol for server objects to be used by `FHIRResource` and subclasses.
 */
public protocol FHIRServer
{
	/** A server object must always have a base URL. */
	var baseURL: NSURL { get }
	
	
	// MARK: - Base Requests
	
	/**
		Instance method that takes a path, which is relative to `baseURL`, executes a GET request from that URL and
		returns a JSON response object in the callback.
		
		:param: path The REST path to request, relative to the server's base URL
		:param: callback The callback to call when the request ends (success or failure)
	 */
	func getJSON(path: String, callback: ((response: FHIRServerJSONResponse) -> Void))
	
	/**
		Instance method that takes a path, which is relative to `baseURL`, executes a PUT request at that URL and
		returns a JSON response object in the callback.
		
		:param: path The REST path to request, relative to the server's base URL
		:param: body The request body data as FHIRJSON
		:param: callback The callback to call when the request ends (success or failure)
	 */
	func putJSON(path: String, body: FHIRJSON, callback: ((response: FHIRServerJSONResponse) -> Void))
	
	/**
		Instance method that takes a path, which is relative to `baseURL`, executes a POST request at that URL and
		returns a JSON response object in the callback.
	
		:param: path The REST path to request, relative to the server's base URL
		:param: body The request body data as FHIRJSON
		:param: callback The callback to call when the request ends (success or failure)
	 */
	func postJSON(path: String, body: FHIRJSON, callback: ((response: FHIRServerJSONResponse) -> Void))
	
	
	// MARK: - Operations
	
	/**
		Performs the given Operation.
	
		The server should first validate the operation and only proceed with execution if validation succeeds.
		
		:param: operation The operation instance to perform
		:param: callback The callback to call when the request ends (success or failure)
	 */
	func perform(operation: FHIROperation, callback: ((response: FHIRServerJSONResponse) -> Void))
}

/**
	Protocol to be used by FHIRServer classes when responding to JSON requests.
 */
public protocol FHIRServerJSONResponse
{
	/// Error that occurred during request or response, if any
	var error: NSError?
	
	/// The JSON response
	var json: FHIRJSON?
}

