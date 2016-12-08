//
//  FHIRString.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 06.12.16.
//  2016, SMART Health IT.
//

import Foundation


/**
Struct to hold on to strings.
*/
public struct FHIRString: FHIRPrimitive, CustomStringConvertible, ExpressibleByStringLiteral {
	
	/// The actual string value.
	public var string: String
	
	/// An optional id of the element.
	public var id: String?
	
	/// The parent/owner of the receiver, if any. Used to dereference resources.
	public weak var _owner: FHIRAbstractBase?
	
	/// Optional extensions of the element.
	public var extension_fhir: [Extension]?
	
	/// Returns true if the string is the empty string.
	public var isEmpty: Bool {
		return string.isEmpty
	}
	
	
	/**
	Designated initializer.
	
	- parameter string: The string represented by the receiver
	*/
	public init(_ string: String) {
		self.string = string
	}
	
	
	// MARK: - FHIRJSONType
	
	public typealias JSONType = String
	
	public init(json: JSONType, owner: FHIRAbstractBase? = nil) throws {
		self.init(json)
		_owner = owner
	}
	
	public func asJSON(errors: inout [FHIRValidationError]) -> JSONType {
		return string
	}
	
	
	// MARK: - ExpressibleByStringLiteral
	
	public init(stringLiteral value: StringLiteralType) {
		self.init(value)
	}
	
	public init(unicodeScalarLiteral value: Character) {
		self.init("\(value)")
	}
	
	public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
		self.init(value)
	}
	
	
	// MARK: - CustomStringConvertible
	
	public var description: String {
		return string
	}
}


extension FHIRString: Equatable, Comparable, Hashable {
	
	public static func ==(l: FHIRString, r: FHIRString) -> Bool {
		return l.string == r.string
	}
	
	public static func ==(l: String, r: FHIRString) -> Bool {
		return l == r.string
	}
	
	public static func ==(l: FHIRString, r: String) -> Bool {
		return l.string == r
	}
	
	
	public static func <(lh: FHIRString, rh: FHIRString) -> Bool {
		return lh.string < rh.string
	}
	
	public static func <(lh: String, rh: FHIRString) -> Bool {
		return lh < rh.string
	}
	
	public static func <(lh: FHIRString, rh: String) -> Bool {
		return lh.string < rh
	}
	
	
	public var hashValue: Int {
        return string.hashValue
    }
}

