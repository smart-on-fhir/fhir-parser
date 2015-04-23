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

/// Error domain used for errors raised during JSON parsing.
public let FHIRJSONErrorDomain = "FHIRJSONError"


/**
 *  Data encoded as a base-64 string.
 */
public struct Base64Binary: StringLiteralConvertible, Printable, Equatable, Comparable
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
		return self(stringLiteral: value)
	}
	
	public static func convertFromStringLiteral(value: String) -> Base64Binary {
		return self(stringLiteral: value)
	}
	
	
	// MARK: - Printable
	
	public var description: String {
		return "<Base64Binary; \(nil != value ? count(value!) : 0) chars>"
	}
}

public func <(lhs: Base64Binary, rhs: Base64Binary) -> Bool {
	return lhs.value < rhs.value
}

public func ==(lhs: Base64Binary, rhs: Base64Binary) -> Bool {
	return lhs.value == rhs.value
}


// MARK: - Helper Functiosn

public func fhir_logIfDebug(log: String) {
#if DEBUG
	println("SwiftFHIR: \(log)")
#endif
}

func fhir_generateJSONError(message: String, code: Int = 0) -> NSError {
	return NSError(domain: FHIRJSONErrorDomain, code: code, userInfo: [NSLocalizedDescriptionKey: message])
}

