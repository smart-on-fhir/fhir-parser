//
//  FHIRReference.swift
//  SMART-on-FHIR
//
//  Created by Pascal Pfiffner on 01/24/15.
//  2015, SMART Platforms.
//

import Foundation


/// Callback from server methods
public typealias FHIRServerJSONResponseCallback = ((response: FHIRServerJSONResponse) -> Void)

/// The FHIR server error domain
public let FHIRServerErrorDomain = "FHIRServerError"


/**
Protocol for server objects to be used by `FHIRResource` and subclasses.
*/
public protocol FHIRServer
{
	/** A server object must always have a base URL. */
	var baseURL: NSURL { get }
	
	/**
	Instance method that takes a path, which is relative to `baseURL`, executes a GET request from that URL and
	returns a decoded JSONDictionary - or an error - in the callback.
	
	:param: path The REST path to request, relative to the server's base URL
	:param: callback The callback to call when the request ends (success or failure)
	*/
	func getJSON(path: String, callback: FHIRServerJSONResponseCallback)
	
	/**
	Instance method that takes a path, which is relative to `baseURL`, executes a PUT request at that URL and
	returns a decoded JSONDictionary - or an error - in the callback.
	
	:param: path The REST path to request, relative to the server's base URL
	:param: body The request body data as JSONDictionary
	:param: callback The callback to call when the request ends (success or failure)
	*/
	func putJSON(path: String, body: JSONDictionary, callback: FHIRServerJSONResponseCallback)
	
	func postJSON(path: String, body: JSONDictionary, callback: FHIRServerJSONResponseCallback)
}


/**
	Encapsulates a server response, which can also indicate that there was no response or request (status >= 600), in
	which case the `error` property carries the only useful information.
 */
public class FHIRServerResponse
{
	/// The HTTP status code
	public let status: Int
	
	/// Response headers
	public let headers: [String: String]
	
	/// An NSError, generated from status code unless it was explicitly assigned.
	public var error: NSError?
	
	public convenience init(notSentBecause error: NSError) {
		self.init(status: 700, headers: [String: String]())
		self.error = error
	}
	
	public required init(status: Int, headers: [String: String]) {
		self.status = status
		self.headers = headers
		
		if status >= 400 {
			let errstr = (status >= 600) ? (status >= 700 ? "No request sent" : "No response received") : NSHTTPURLResponse.localizedStringForStatusCode(status)
			error = NSError(domain: FHIRServerErrorDomain, code: status, userInfo: [NSLocalizedDescriptionKey: errstr])
		}
	}
	
	
	/** Instantiate a FHIRServerJSONResponse from an NS(HTTP)URLResponse. */
	public class func from(# response: NSURLResponse) -> Self {
		var status = 0
		var headers = [String: String]()
		
		if let http = response as? NSHTTPURLResponse {
			status = http.statusCode
			for (key, val) in http.allHeaderFields {
				if let keystr = key as? String {
					if let valstr = val as? String {
						headers[keystr] = valstr
					}
					else {
						println("DEBUG: Not a string in location headers: \(val) (for \(keystr))")
					}
				}
			}
		}
		
		return self(status: status, headers: headers)
	}
	
	/** Initializes with a status of 600 to signal that no response was received. */
	public class func noneReceived() -> Self {
		return self(status: 600, headers: [String: String]())
	}
}


/**
	Encapsulates a server response with JSON response body, if any.
 */
public class FHIRServerJSONResponse: FHIRServerResponse
{
	/// The response body, decoded into a JSONDictionary
	public var body: JSONDictionary?
	
	public required init(status: Int, headers: [String: String]) {
		super.init(status: status, headers: headers)
	}

	/**
		Instantiate a FHIRServerJSONResponse from an NS(HTTP)URLResponse and NSData.
		
		If the status is >= 400, the response body is checked for an OperationOutcome and its first issue item is
		turned into an error message.
	 */
	public class func from(# response: NSURLResponse, data inData: NSData?) -> Self {
		let sup = super.from(response: response)
		let res = self(status: sup.status, headers: sup.headers)		// TODO: figure out how to make super work with "Self"
		
		if let data = inData {
			var error: NSError? = nil
			if let json = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &error) as? JSONDictionary {
				res.body = json
				
				// check for OperationOutcome if there was an error
				if res.status >= 400 {
					if let erritem = res.resource(OperationOutcome)?.issue?.first {
						let none = "unknown"
						let errstr = "\(erritem.severity ?? none): \(erritem.details ?? none)"
						res.error = genServerError(errstr, code: res.status)
					}
				}
			}
			else {
				let errstr = "Failed to deserialize JSON into a dictionary: \(error?.localizedDescription)\n"
				             "\(NSString(data: data, encoding: NSUTF8StringEncoding))"
				res.error = genServerError(errstr, code: res.status)
			}
		}
		
		return res
	}
	
	
	// MARK: - Resource Handling
	
	/** Uses FHIRElement's factory method to instantiate a resource from the response JSON, if any, and returns that
		resource. */
	public func resource<T: FHIRElement>(expectType: T.Type) -> T? {
		if let json = body {
			let resource = FHIRElement.instantiateFrom(json, owner: nil)
			return resource as? T
		}
		return nil
	}
}


/** Create an error in the FHIRServerErrorDomain error domain. */
func genServerError(message: String, code: Int = 0) -> NSError {
	return NSError(domain: FHIRServerErrorDomain, code: code, userInfo: [NSLocalizedDescriptionKey: message])
}

