//
//  FHIRServerResponse.swift
//  SwiftSMART
//
//  Created by Pascal Pfiffner on 3/31/15.
//  2015, SMART Platforms.
//

import Foundation


/**
Encapsulates a server response, which can also indicate that there was no response or not even a request, in which case the `error`
property carries the only useful information.
*/
public protocol FHIRServerResponse {
	
	/// The HTTP status code.
	var status: Int { get }
	
	/// Response headers.
	var headers: [String: String] { get }
	
	/// The response body data.
	var body: NSData? { get }
	
	/// The request's operation outcome, if any.
	var outcome: OperationOutcome? { get }
	
	/// The error encountered, if any.
	var error: FHIRError? { get }
	
	
	/**
	Instantiate a FHIRServerResponse from an NS(HTTP)URLResponse, NSData and an NSError.
	*/
	init(response: NSURLResponse, data: NSData?, urlError: NSError?)
	
	init(error: ErrorType)
	
	
	// MARK: - Responses
	
	func responseResource<T: Resource>(expectType: T.Type) -> T?
	
	/**
	The response should inspect response headers and update resource data like `id` and `meta` accordingly.
	
	This method must not be called if the response has a non-nil error.
	
	- throws: The method should only throw on severe cases, like if Location headers were returned that don't match the resource type
	- parameter resource: The resource to apply response data to
	*/
	func applyResponseHeadersToResource(resource: Resource) throws
	
	/**
	The response should apply response body data to the given resource. It should throw `FHIRError.ResponseNoResourceReceived` if there was
	no response data.
	
	This method must not be called if the response has a non-nil error.
	
	- throws:   The method should throw if resource data was returned that doesn't match the given resource's type, but also if there was no
	            response data at all (`FHIRError.ResponseNoResourceReceived` in that case)
	- parameter resource: The resource to apply response data to
	*/
	func applyResponseBodyToResource(resource: Resource) throws
	
	static func noneReceived() -> Self
}

