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
	
	func applyToResource(resource: Resource)
	
	static func noneReceived() -> Self
}

