//
//  FHIRInteger.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 08.12.16.
//  2016, SMART Health IT.
//

import Foundation


/**
Struct to hold on to a 32-bit integer value.
*/
public struct FHIRInteger: FHIRPrimitive, LosslessStringConvertible, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
	
	/// The actual decimal value.
	public var int: Int32
	
	/// An optional id of the element.
	public var id: String?
	
	/// The parent/owner of the receiver, if any. Used to dereference resources.
	public weak var _owner: FHIRAbstractBase?
	
	/// Optional extensions of the element.
	public var extension_fhir: [Extension]?
	
	
	/**
	Designated initializer.
	
	- parameter int: The integer to represent.
	*/
	public init(int: Int32) {
		self.int = int
	}
	
	
	// MARK: - FHIRJSONType
	#if os(Linux)
	public typealias JSONType = Int
	#else
	public typealias JSONType = NSNumber
	#endif
	
	public init(json: JSONType, owner: FHIRAbstractBase? = nil) throws {
		#if os(Linux)
		self.init(int: Int32(json))
		#else
		self.init(int: Int32(json.intValue))
		#endif
		_owner = owner
	}
	
	public func asJSON(errors: inout [FHIRValidationError]) -> JSONType {
		#if os(Linux)
		return int
		#else
		return NSNumber(value: int)
		#endif
	}
	
	
	// MARK: - LosslessStringConvertible & CustomStringConvertible
	
	public init?(_ description: String) {
		guard let int = Int32(description) else {
			return nil
		}
		self.init(int: int)
	}
	
	public var description: String {
		return int.description
	}
	
	
	// MARK: - ExpressibleBy
	
	public init(stringLiteral string: StringLiteralType) {
		let int = Int32(string)
		self.init(int: int ?? Int32())
	}
	
	public init(unicodeScalarLiteral value: Character) {
		self.init(stringLiteral: "\(value)")
	}
	
	public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
		self.init(stringLiteral: value)
	}
	
	public init(booleanLiteral bool: Bool) {
		self.init(int: bool ? 1 : 0)
	}
	
	public init(integerLiteral integer: Int) {
		self.init(int: Int32(integer))
	}
}

extension FHIRInteger: Equatable, Comparable {
	
	public static func ==(l: FHIRInteger, r: FHIRInteger) -> Bool {
		return l.int == r.int
	}
	
	public static func ==(l: Int, r: FHIRInteger) -> Bool {
		return Int32(l) == r.int
	}
	
	public static func ==(l: FHIRInteger, r: Int) -> Bool {
		return l.int == Int32(r)
	}
	
	
	public static func <(lh: FHIRInteger, rh: FHIRInteger) -> Bool {
		return lh.int < rh.int
	}
	
	public static func <(lh: Int, rh: FHIRInteger) -> Bool {
		return Int32(lh) < rh.int
	}
	
	public static func <(lh: FHIRInteger, rh: Int) -> Bool {
		return lh.int < Int32(rh)
	}
}

