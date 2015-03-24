//
//  FHIRReference.swift
//  SMART-on-FHIR
//
//  Created by Pascal Pfiffner on 01/24/15.
//  2015, SMART Platforms.
//

import Foundation


/// The FHIR server error domain.
public let FHIRServerErrorDomain = "FHIRServerError"

/// Describing HTTP request types.
public enum FHIRRequestType
{
	case GET, PUT, POST
	
	func prepareRequest(req: NSMutableURLRequest, body: NSData? = nil) {
		switch self {
		case .GET:
			req.HTTPMethod = "GET"
			req.setValue("application/json+fhir", forHTTPHeaderField: "Accept")
			req.setValue("UTF-8", forHTTPHeaderField: "Accept-Charset")
		case .PUT:
			req.HTTPMethod = "PUT"
			req.setValue("application/json+fhir; charset=utf-8", forHTTPHeaderField: "Content-Type")
			req.setValue("application/json+fhir", forHTTPHeaderField: "Accept")
			req.setValue("UTF-8", forHTTPHeaderField: "Accept-Charset")
			req.HTTPBody = body
		case .POST:
			req.HTTPMethod = "POST"
			// TODO: set headers
			req.HTTPBody = body
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
		:param: body The request body data as JSONDictionary
		:param: callback The callback to call when the request ends (success or failure)
	*/
	func putJSON(path: String, body: JSONDictionary, callback: ((response: FHIRServerJSONResponse) -> Void))
	
	func postJSON(path: String, body: JSONDictionary, callback: ((response: FHIRServerJSONResponse) -> Void))
}



// MARK: - Request Preparation


/**
	Base for different request/response handlers. Would love to make this a protocol but since it has an associated
	type it cannot be used nicely, hence a class.
 */
public class FHIRServerRequestHandler
{
	public typealias ResponseType = FHIRServerResponse
	
	public let type: FHIRRequestType
	
	public init(_ type: FHIRRequestType) {
		self.type = type
	}
	
	public func prepareRequest(req: NSMutableURLRequest, error: NSErrorPointer) -> Bool {
		type.prepareRequest(req)
		return true
	}
	
	public func response(# response: NSURLResponse?, data inData: NSData? = nil) -> ResponseType {
		if let res = response {
			return self.dynamicType.ResType(response: res, data: inData)
		}
		return self.dynamicType.ResType.noneReceived()
	}
	
	public func notSent(reason: String) -> ResponseType {
		return self.dynamicType.ResType(notSentBecause: genServerError(reason, code: 700))
	}
	
	class var ResType: FHIRServerResponse.Type {
		return FHIRServerResponse.self
	}
}

public class FHIRServerDataRequestHandler: FHIRServerRequestHandler
{
	public typealias ResponseType = FHIRServerDataResponse
	
	public var data: NSData?
	
	public init(_ type: FHIRRequestType, data: NSData? = nil) {
		super.init(type)
		self.data = data
	}
	
	public func prepareData(error: NSErrorPointer) -> Bool {
		return true
	}
	
	public override func prepareRequest(req: NSMutableURLRequest, error: NSErrorPointer) -> Bool {
		if prepareData(error) {
			type.prepareRequest(req, body: data)
			return true
		}
		return false
	}
	
	override class var ResType: FHIRServerResponse.Type {
		return FHIRServerDataResponse.self
	}
}

public class FHIRServerJSONRequestHandler: FHIRServerDataRequestHandler
{
	public typealias ResponseType = FHIRServerJSONResponse
	
	public var json: JSONDictionary?
	
	public init(_ type: FHIRRequestType, json: JSONDictionary? = nil) {
		super.init(type)
		self.json = json
	}
	
	override public func prepareData(error: NSErrorPointer) -> Bool {
		if nil == data && nil != json {
			data = NSJSONSerialization.dataWithJSONObject(json!, options: nil, error: error)
			return nil != data
		}
		return true
	}
	
	override class var ResType: FHIRServerResponse.Type {
		return FHIRServerJSONResponse.self
	}
}


// MARK: - Response Handling


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
	public var error: NSError? {
		get {
			if nil == _error && status >= 400 {
				let errstr = (status >= 600) ? (status >= 700 ? "No request sent" : "No response received") : NSHTTPURLResponse.localizedStringForStatusCode(status)
				_error = genServerError(errstr, code: status)
			}
			return _error
		}
		set {
			_error = newValue
		}
	}
	private var _error: NSError?
	
	public required init(status: Int, headers: [String: String]) {
		self.status = status
		self.headers = headers
	}
	
	/**
		Instantiate a FHIRServerResponse from an NS(HTTP)URLResponse and NSData.
	 */
	public required init(response: NSURLResponse, data: NSData?) {
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
		
		self.status = status
		self.headers = headers
	}
	
	public required init(notSentBecause: NSError) {
		status = 700
		headers = [String: String]()
		error = notSentBecause
	}
	
	/** Initializes with a status of 600 to signal that no response was received. */
	public class func noneReceived() -> Self {
		return self(status: 600, headers: [String: String]())
	}
}

/**
	Encapsulates a server response holding an NSData body.
 */
public class FHIRServerDataResponse: FHIRServerResponse
{
	/// The response body data
	public var body: NSData?
	
	public required init(status: Int, headers: [String: String]) {
		super.init(status: status, headers: headers)
	}
	
	public required init(response: NSURLResponse, data inData: NSData?) {
		super.init(response: response, data: inData)
		if let data = inData {
			body = data
		}
	}
	
	public required init(notSentBecause error: NSError) {
		super.init(notSentBecause: error)
	}
}

/**
	Encapsulates a server response with JSON response body, if any.
 */
public class FHIRServerJSONResponse: FHIRServerDataResponse
{
	/// The response body, decoded into a JSONDictionary
	public var json: JSONDictionary?
	
	public required init(status: Int, headers: [String: String]) {
		super.init(status: status, headers: headers)
	}
	
	/**
		If the status is >= 400, the response body is checked for an OperationOutcome and its first issue item is
		turned into an error message.
	 */
	public required init(response: NSURLResponse, data inData: NSData?) {
		super.init(response: response, data: inData)
		
		if let data = inData {
			var error: NSError? = nil
			if let json = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &error) as? JSONDictionary {
				self.json = json
				
				// check for OperationOutcome if there was an error
				if status >= 400 {
					if let erritem = resource(OperationOutcome)?.issue?.first {
						let none = "unknown"
						let errstr = "[\(erritem.severity ?? none)] \(erritem.details ?? none)"
						self.error = genServerError(errstr, code: status)
					}
				}
			}
			else {
				let errstr = "Failed to deserialize JSON into a dictionary: \(error?.localizedDescription)\n"
				             "\(NSString(data: data, encoding: NSUTF8StringEncoding))"
				self.error = genServerError(errstr, code: status)
			}
		}
	}
	
	public required init(notSentBecause error: NSError) {
		super.init(notSentBecause: error)
	}
	
	/** Uses FHIRElement's factory method to instantiate a resource from the response JSON, if any, and returns that
		resource. */
	public func resource<T: FHIRElement>(expectType: T.Type) -> T? {
		if let json = self.json {
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

