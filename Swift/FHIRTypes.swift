//
//  FHIRTypes.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 12/16/14.
//  2014, SMART Health IT.
//

import Foundation


/**
 *  A JSON dictionary, with `String` keys and `AnyObject` values.
 */
public typealias FHIRJSON = [String: AnyObject]

/**
	Errors thrown during JSON parsing.
 */
public struct FHIRJSONError: ErrorType, CustomStringConvertible {
	
	public let _domain = "FHIRJSONError"
	
	public var _code: Int {
		return 0
	}
	
	public var code: FHIRJSONErrorType
	
	/// The JSON property key generating the error.
	public var key: String
	
	/// The type expected for values of this key.
	public var wants: Any.Type?
	
	/// The type received for this key.
	public var has: Any.Type?
	
	
	init(code: FHIRJSONErrorType, key: String) {
		self.code = code
		self.key = key
	}
	
	public init(key: String) {
		self.init(code: .MissingKey, key: key)
	}
	
	public init(key: String, has: Any.Type) {
		self.init(code: .UnknownKey, key: key)
		self.has = has
	}
	
	public init(key: String, wants: Any.Type, has: Any.Type) {
		self.init(code: .WrongValueForKey, key: key)
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
		case .WrongValueForKey:
			return "Expecting JSON property “\(key)” to be `\(wants ?? nul)`, but is \(has ?? nul)"
		}
	}
}

public enum FHIRJSONErrorType: Int
{
	case MissingKey
	case UnknownKey
	case WrongValueForKey
}


/**
 *  Data encoded as a base-64 string.
 */
public struct Base64Binary: StringLiteralConvertible, CustomStringConvertible, Equatable, Comparable
{
	public typealias UnicodeScalarLiteralType = Character
	public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
	
	var value: String?
	
	public init(value: String) {
		self.value = value
	}
	
	
	// MARK: - String Literal Convertible
	
	public init(stringLiteral value: StringLiteralType) {
		self.value = value
	}
	
	public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
		self.value = "\(value)"
	}
	
	public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
		self.value = value
	}
	
	public static func convertFromExtendedGraphemeClusterLiteral(value: String) -> Base64Binary {
		return self.init(stringLiteral: value)
	}
	
	public static func convertFromStringLiteral(value: String) -> Base64Binary {
		return self.init(stringLiteral: value)
	}
	
	
	// MARK: - Printable
	
	public var description: String {
		return "<Base64Binary; \(nil != value ? value!.characters.count : 0) chars>"
	}
}

public func <(lhs: Base64Binary, rhs: Base64Binary) -> Bool {
	return lhs.value < rhs.value
}

public func ==(lhs: Base64Binary, rhs: Base64Binary) -> Bool {
	return lhs.value == rhs.value
}


// MARK: - Helper Functiosn

public func fhir_logIfDebug(@autoclosure message: () -> String, function: String = __FUNCTION__, file: NSString = __FILE__, line: Int = __LINE__) {
#if DEBUG
	print("SwiftFHIR [\(file.lastPathComponent):\(line)] \(function)  \(message())")
#endif
}

public func fhir_warn(@autoclosure message: () -> String, function: String = __FUNCTION__, file: NSString = __FILE__, line: Int = __LINE__) {
	print("SwiftFHIR [\(file.lastPathComponent):\(line)] \(function)  WARNING: \(message())")
}

