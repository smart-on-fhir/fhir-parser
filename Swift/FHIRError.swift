//
//  FHIRError.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 11/24/15.
//  2015, SMART Health IT.
//

import Foundation


/**
FHIR errors.
*/
public enum FHIRError: Error, CustomStringConvertible {
	case error(String)
	
	case resourceLocationUnknown
	case resourceWithoutServer
	case resourceWithoutId
	case resourceAlreadyHasId
	case resourceFailedToInstantiate(String)
	case resourceCannotContainItself
	
	case requestCannotPrepareBody
	case requestNotSent(String)
	case requestError(Int, String)
	case noRequestHandlerAvailable(String)
	case noResponseReceived
	case responseLocationHeaderResourceTypeMismatch(String, String)
	case responseNoResourceReceived
	
	/// The resource type received (1st String) does not match the expected type (2nd String).
	case responseResourceTypeMismatch(String, String)
	
	case operationConfigurationError(String)
	case operationInputParameterMissing(String)
	case operationNotSupported(String)
	
	case searchResourceTypeNotDefined
	
	/// JSON parsing failed for reason in 1st argument, full JSON string is 2nd argument.
	case jsonParsingError(String, String)
	
	public var description: String {
		switch self {
		case .error(let message):
			return message
		
		case .resourceLocationUnknown:
			return "The location of the resource is not known".fhir_localized
		case .resourceWithoutServer:
			return "The resource does not have a server instance assigned".fhir_localized
		case .resourceWithoutId:
			return "The resource does not have an id, cannot proceed".fhir_localized
		case .resourceAlreadyHasId:
			return "The resource already have an id, cannot proceed".fhir_localized
		case .resourceFailedToInstantiate(let path):
			return "\("Failed to instantiate resource when trying to read from".fhir_localized): «\(path)»"
		case .resourceCannotContainItself:
			return "A resource cannot contain itself".fhir_localized
		
		case .requestCannotPrepareBody:
			return "`FHIRServerRequestHandler` cannot prepare request body data".fhir_localized
		case .requestNotSent(let reason):
			return "\("Request not sent".fhir_localized): \(reason)"
		case .requestError(let status, let message):
			return "\("Error".fhir_localized) \(status): \(message)"
		case .noRequestHandlerAvailable(let type):
			return "\("No request handler is available for requests of type".fhir_localized) “\(type)”"
		case .noResponseReceived:
			return "No response received".fhir_localized
		case .responseLocationHeaderResourceTypeMismatch(let location, let expectedType):
			return "\("“Location” header resource type mismatch. Expecting".fhir_localized) “\(expectedType)” \("in".fhir_localized) “\(location)”"
		case .responseNoResourceReceived:
			return "No resource data was received with the response".fhir_localized
		case .responseResourceTypeMismatch(let receivedType, let expectedType):
			return "Returned resource is of wrong type, expected “\(expectedType)” but received “\(receivedType)”"
		
		case .operationConfigurationError(let message):
			return message
		case .operationInputParameterMissing(let name):
			return "\("Operation is missing input parameter".fhir_localized): “\(name)”"
		case .operationNotSupported(let name):
			return "\("Operation is not supported".fhir_localized): \(name)"
			
		case .searchResourceTypeNotDefined:
			return "Cannot find the resource type against which to run the search".fhir_localized
		
		case .jsonParsingError(let reason, let raw):
			return "\("Failed to parse JSON".fhir_localized): \(reason)\n\(raw)"
		}
	}
}


/**
Errors thrown during JSON parsing.
*/
public struct FHIRJSONError: Error, CustomStringConvertible {
	
	/// The error type.
	public var code: FHIRJSONErrorType
	
	/// The JSON property key generating the error.
	public var key: String
	
	/// The type expected for values of this key.
	public var wants: Any.Type?
	
	/// The type received for this key.
	public var has: Any.Type?
	
	/// A problem description.
	public var problem: String?
	
	
	/** Designated initializer. */
	init(code: FHIRJSONErrorType, key: String) {
		self.code = code
		self.key = key
	}
	
	/** Initializer to use when a given JSON key is missing. */
	public init(key: String) {
		self.init(code: .missingKey, key: key)
	}
	
	/** Initializer to use when a given JSON key is present but is not expected. */
	public init(key: String, has: Any.Type) {
		self.init(code: .unknownKey, key: key)
		self.has = has
	}
	
	/** Initializer to use when there is a problem with a given JSON key (other than the key missing or being unknown). */
	public init(key: String, problem: String) {
		self.init(code: .problemWithValueForKey, key: key)
		self.problem = problem
	}
	
	/** Initializer to use when the given JSON key is of a wrong type. */
	public init(key: String, wants: Any.Type, has: Any.Type) {
		self.init(code: .wrongValueTypeForKey, key: key)
		self.wants = wants
		self.has = has
	}
	
	public var description: String {
		let nul = Any.self
		switch code {
		case .missingKey:
			return "Expecting nonoptional JSON property “\(key)” but it is missing"
		case .unknownKey:
			return "Superfluous JSON property “\(key)” of type \(has ?? nul), ignoring"
		case .wrongValueTypeForKey:
			return "Expecting JSON property “\(key)” to be `\(wants ?? nul)`, but is \(has ?? nul)"
		case .problemWithValueForKey:
			return "Problem with JSON property “\(key)”: \(problem ?? "(problem not described)")"
		}
	}
}


public enum FHIRJSONErrorType: Int {
	case missingKey
	case unknownKey
	case wrongValueTypeForKey
	case problemWithValueForKey
}

