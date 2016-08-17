//
//  FHIRTypes.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 12/16/14.
//  2014, SMART Health IT.
//

import Foundation


/**
A JSON dictionary, with `String` keys and `AnyObject` values.
*/
public typealias FHIRJSON = [String: AnyObject]


/**
Data encoded as a base-64 string.
*/
public struct Base64Binary: StringLiteralConvertible, CustomStringConvertible, Equatable, Comparable {
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


// MARK: - Helper Functions

extension String {
	/**
	Convenience getter using `NSLocalizedString()` with no comment.
	*/
	public var fhir_localized: String {
		return NSLocalizedString(self, comment: "")
	}
}

/**
Execute a `print()`, prepending filename, line and function/method name, if `DEBUG` is defined.
*/
public func fhir_logIfDebug(@autoclosure message: () -> String, function: String = #function, file: NSString = #file, line: Int = #line) {
#if DEBUG
	print("SwiftFHIR [\(file.lastPathComponent):\(line)] \(function)  \(message())")
#endif
}

/**
Execute a `print()`, prepending filename, line and function/method name and "WARNING" prepended.
*/
public func fhir_warn(@autoclosure message: () -> String, function: String = #function, file: NSString = #file, line: Int = #line) {
	print("SwiftFHIR [\(file.lastPathComponent):\(line)] \(function)  WARNING: \(message())")
}

