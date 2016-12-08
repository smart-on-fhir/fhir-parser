//
//  FHIRBool.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 08.12.16.
//  2016, SMART Health IT.
//

import Foundation


/**
Struct to hold on to a boolean value.
*/
public struct FHIRBool: FHIRPrimitive, LosslessStringConvertible, ExpressibleByBooleanLiteral {
	
	/// The actual string value.
	public var bool: Bool
	
	/// An optional id of the element.
	public var id: String?
	
	/// The parent/owner of the receiver, if any. Used to dereference resources.
	public weak var _owner: FHIRAbstractBase?
	
	/// Optional extensions of the element.
	public var extension_fhir: [Extension]?
	
	
	/**
	Designated initializer.
	
	- parameter flag: The boolean to represent with the receiver
	*/
	public init(_ flag: Bool) {
		bool = flag
	}
	
	
	// MARK: - FHIRJSONType
	
	public typealias JSONType = Bool
	
	public init(json: JSONType, owner: FHIRAbstractBase? = nil) throws {
		self.init(json)
		_owner = owner
	}
	
	public func asJSON(errors: inout [FHIRValidationError]) -> JSONType {
		return bool
	}
	
	
	// MARK: - ExpressibleByBooleanLiteral
	
	public init(booleanLiteral value: BooleanLiteralType) {
		self.init(value)
	}
	
	
	// MARK: - LosslessStringConvertible & CustomStringConvertible
	
	public init?(_ description: String) {
		guard let flag = Bool(description) else {
			return nil
		}
		bool = flag
	}
	
	public var description: String {
		return bool.description
	}
	
	
	//  MARK: - Operator Functions
	
	public prefix static func !(a: FHIRBool) -> Bool {
		return !a.bool
	}
	
	@inline(__always)
	public static func &&(lhs: FHIRBool, rhs: @autoclosure () throws -> FHIRBool) rethrows -> Bool {
		return try lhs.bool && rhs().bool
	}
	
	@inline(__always)
	public static func &&(lhs: FHIRBool, rhs: @autoclosure () throws -> Bool) rethrows -> Bool {
		return try lhs.bool && rhs()
	}
	
	@inline(__always)
	public static func ||(lhs: FHIRBool, rhs: @autoclosure () throws -> FHIRBool) rethrows -> Bool {
		return try lhs.bool || rhs().bool
	}
	
	@inline(__always)
	public static func ||(lhs: FHIRBool, rhs: @autoclosure () throws -> Bool) rethrows -> Bool {
		return try lhs.bool || rhs()
	}
}


extension FHIRBool: Equatable, Hashable {
	
	public static func ==(l: FHIRBool, r: FHIRBool) -> Bool {
		return l.bool == r.bool
	}
	
	public static func ==(l: Bool, r: FHIRBool) -> Bool {
		return l == r.bool
	}
	
	public static func ==(l: FHIRBool, r: Bool) -> Bool {
		return l.bool == r
	}
	
	
	public var hashValue: Int {
        return bool.hashValue
    }
}

