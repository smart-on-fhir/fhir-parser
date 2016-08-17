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
public enum FHIRError: ErrorType, CustomStringConvertible {
	case Error(String)
	
	case ResourceLocationUnknown
	case ResourceWithoutServer
	case ResourceWithoutId
	case ResourceAlreadyHasId
	case ResourceFailedToInstantiate(String)
	case ResourceCannotContainItself
	
	case RequestCannotPrepareBody
	case RequestNotSent(String)
	case RequestError(Int, String)
	case NoRequestHandlerAvailable(String)
	case NoResponseReceived
	case ResponseLocationHeaderResourceTypeMismatch(String, String)
	case ResponseNoResourceReceived
	case ResponseResourceTypeMismatch(String, String)
	
	case OperationConfigurationError(String)
	case OperationInputParameterMissing(String)
	case OperationNotSupported(String)
	
	case SearchResourceTypeNotDefined
	
	/// JSON parsing failed for reason in 1st argument, full JSON string is 2nd argument.
	case JSONParsingError(String, String)
	
	public var description: String {
		switch self {
		case .Error(let message):
			return message
		
		case .ResourceLocationUnknown:
			return "The location of the resource is not known".fhir_localized
		case .ResourceWithoutServer:
			return "The resource does not have a server instance assigned".fhir_localized
		case .ResourceWithoutId:
			return "The resource does not have an id, cannot proceed".fhir_localized
		case .ResourceAlreadyHasId:
			return "The resource already have an id, cannot proceed".fhir_localized
		case .ResourceFailedToInstantiate(let path):
			return "\("Failed to instantiate resource when trying to read from".fhir_localized): «\(path)»"
		case .ResourceCannotContainItself:
			return "A resource cannot contain itself".fhir_localized
		
		case .RequestCannotPrepareBody:
			return "`FHIRServerRequestHandler` cannot prepare request body data".fhir_localized
		case .RequestNotSent(let reason):
			return "\("Request not sent".fhir_localized): \(reason)"
		case .RequestError(let status, let message):
			return "\("Error".fhir_localized) \(status): \(message)"
		case .NoRequestHandlerAvailable(let type):
			return "\("No request handler is available for requests of type".fhir_localized) “\(type)”"
		case .NoResponseReceived:
			return "No response received".fhir_localized
		case .ResponseLocationHeaderResourceTypeMismatch(let location, let expectedType):
			return "\("“Location” header resource type mismatch. Expecting".fhir_localized) “\(expectedType)” \("in".fhir_localized) “\(location)”"
		case .ResponseNoResourceReceived:
			return "No resource data was received with the response".fhir_localized
		case .ResponseResourceTypeMismatch(let receivedType, let expectedType):
			return "Returned resource is of wrong type, expected “\(expectedType)” but received “\(receivedType)”"
		
		case .OperationConfigurationError(let message):
			return message
		case .OperationInputParameterMissing(let name):
			return "\("Operation is missing input parameter".fhir_localized): “\(name)”"
		case .OperationNotSupported(let name):
			return "\("Operation is not supported".fhir_localized): \(name)"
			
		case .SearchResourceTypeNotDefined:
			return "Cannot find the resource type against which to run the search".fhir_localized
		
		case .JSONParsingError(let reason, let raw):
			return "\("Failed to parse JSON".fhir_localized): \(reason)\n\(raw)"
		}
	}
}


/**
Errors thrown during JSON parsing.
*/
public struct FHIRJSONError: ErrorType, CustomStringConvertible {
	
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
		self.init(code: .MissingKey, key: key)
	}
	
	/** Initializer to use when a given JSON key is present but is not expected. */
	public init(key: String, has: Any.Type) {
		self.init(code: .UnknownKey, key: key)
		self.has = has
	}
	
	/** Initializer to use when there is a problem with a given JSON key (other than the key missing or being unknown). */
	public init(key: String, problem: String) {
		self.init(code: .ProblemWithValueForKey, key: key)
		self.problem = problem
	}
	
	/** Initializer to use when the given JSON key is of a wrong type. */
	public init(key: String, wants: Any.Type, has: Any.Type) {
		self.init(code: .WrongValueTypeForKey, key: key)
		self.wants = wants
		self.has = has
	}
	
	public var description: String {
		let nul = Any.self
		switch code {
		case .MissingKey:
			return "Expecting nonoptional JSON property “\(key)” but it is missing"
		case .UnknownKey:
			return "Superfluous JSON property “\(key)” of type \(has ?? nul), ignoring"
		case .WrongValueTypeForKey:
			return "Expecting JSON property “\(key)” to be `\(wants ?? nul)`, but is \(has ?? nul)"
		case .ProblemWithValueForKey:
			return "Problem with JSON property “\(key)”: \(problem ?? "(problem not described)")"
		}
	}
}


public enum FHIRJSONErrorType: Int {
	case MissingKey
	case UnknownKey
	case WrongValueTypeForKey
	case ProblemWithValueForKey
}

