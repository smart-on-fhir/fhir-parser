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
	
	/// The actual 32-bit integer value.
	public var int32: Int32
	
	/// The value as an `Int`, computed from `int32`.
	public var int: Int {
		return Int(int32)
	}
	
	/// An optional id of the element.
	public var id: String?
	
	/// The parent/owner of the receiver, if any. Used to dereference resources.
	public weak var _owner: FHIRAbstractBase?
	
	/// Optional extensions of the element.
	public var extension_fhir: [Extension]?
	
	
	/**
	Designated initializer.
	
	- parameter int: The 32-bit integer to represent.
	*/
	public init(_ int32: Int32) {
		self.int32 = int32
	}
	
	
	// MARK: - FHIRJSONType
	#if os(Linux)
	public typealias JSONType = Int
	#else
	public typealias JSONType = NSNumber
	#endif
	
	public init(json: JSONType, owner: FHIRAbstractBase? = nil) throws {
		#if os(Linux)
		self.init(Int32(json))
		#else
		self.init(Int32(json.intValue))
		#endif
		_owner = owner
	}
	
	public func asJSON(errors: inout [FHIRValidationError]) -> JSONType {
		#if os(Linux)
		return int
		#else
		return NSNumber(value: int32)
		#endif
	}
	
	
	// MARK: - LosslessStringConvertible & CustomStringConvertible
	
	public init?(_ description: String) {
		guard let int32 = Int32(description) else {
			return nil
		}
		self.init(int32)
	}
	
	public var description: String {
		return int32.description
	}
	
	
	// MARK: - ExpressibleBy
	
	public init(stringLiteral string: StringLiteralType) {
		let int32 = Int32(string)
		self.init(int32 ?? Int32())
	}
	
	public init(unicodeScalarLiteral value: Character) {
		self.init(stringLiteral: "\(value)")
	}
	
	public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
		self.init(stringLiteral: value)
	}
	
	public init(booleanLiteral bool: Bool) {
		self.init(bool ? 1 : 0)
	}
	
	public init(integerLiteral integer: Int) {
		self.init(Int32(integer))
	}
}

extension FHIRInteger: Equatable, Comparable {
	
	public static func ==(l: FHIRInteger, r: FHIRInteger) -> Bool {
		return l.int32 == r.int32
	}
	
	public static func ==(l: Int, r: FHIRInteger) -> Bool {
		return Int32(l) == r.int32
	}
	
	public static func ==(l: FHIRInteger, r: Int) -> Bool {
		return l.int32 == Int32(r)
	}
	
	
	public static func <(lh: FHIRInteger, rh: FHIRInteger) -> Bool {
		return lh.int32 < rh.int32
	}
	
	public static func <(lh: Int, rh: FHIRInteger) -> Bool {
		return Int32(lh) < rh.int32
	}
	
	public static func <(lh: FHIRInteger, rh: Int) -> Bool {
		return lh.int32 < Int32(rh)
	}
}

