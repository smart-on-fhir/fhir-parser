//
//  Base64Binary.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 07.12.16.
//  2016, SMART Health IT.
//

import Foundation


/**
Data encoded as a base-64 string.
*/
public struct Base64Binary: FHIRPrimitive, FHIRJSONType, ExpressibleByStringLiteral, CustomStringConvertible {
	
	/// The base-64 string.
	var value: String
	
	/// An optional id of the element.
	public var id: String?
	
	/// The parent/owner of the receiver, if any. Used to dereference resources.
	public weak var _owner: FHIRAbstractBase?
	
	/// Optional extensions of the element.
	public var extension_fhir: [Extension]?
	
	
	/**
	Designated initializer.
	
	- parameter value: The Base64 string representing data of the receiver
	*/
	public init(value: String) {
		self.value = value
	}
	
	
	// MARK: - FHIRJSONType
	
	public typealias JSONType = String
	
	public init(json: JSONType, owner: FHIRAbstractBase? = nil) throws {
		self.init(value: json)
		_owner = owner
	}
	
	public func asJSON(errors: inout [FHIRValidationError]) -> JSONType {
		return value
	}
	
	
	// MARK: - ExpressibleByStringLiteral
	
	public init(stringLiteral value: StringLiteralType) {
		self.value = value
	}
	
	public init(unicodeScalarLiteral value: Character) {
		self.value = "\(value)"
	}
	
	public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
		self.value = value
	}
	
	
	// MARK: - Printable, Equatable and Comparable
	
	public var description: String {
		return "<Base64Binary; \(value.characters.count) chars>"
	}
}


extension Base64Binary: Equatable, Comparable {
	
	public static func ==(lhs: Base64Binary, rhs: Base64Binary) -> Bool {
		return lhs.value == rhs.value
	}
	
	public static func <(lh: Base64Binary, rh: Base64Binary) -> Bool {
		return lh.value < rh.value
	}
}

