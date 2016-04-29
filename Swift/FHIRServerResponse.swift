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
	The response ideally inspects response headers and updates resource data like `id` and `meta` accordingly. If the response body carries
	resource data, it should update the resource.
	
	This method must not be called if the response has a non-nil error.
	
	- parameter resource: The resource to apply response data to
	*/
	func applyToResource(resource: Resource)
	
	static func noneReceived() -> Self
}

