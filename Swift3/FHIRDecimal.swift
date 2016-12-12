//
//  FHIRNumbers.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 08.12.16.
//  2016, SMART Health IT.
//

import Foundation


/**
Struct to hold on to a decimal value.

By design, FHIRDecimal does not conform to `ExpressibleByFloatLiteral` in order to avoid precision issues.
*/
public struct FHIRDecimal: FHIRPrimitive, LosslessStringConvertible, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
	
	/// The actual decimal value.
	public var decimal: Decimal
	
	/// An optional id of the element.
	public var id: String?
	
	/// The parent/owner of the receiver, if any. Used to dereference resources.
	public weak var _owner: FHIRAbstractBase?
	
	/// Optional extensions of the element.
	public var extension_fhir: [Extension]?
	
	
	/**
	Designated initializer.
	
	- parameter dcm: The decimal to represent.
	*/
	public init(_ dcm: Decimal) {
		decimal = dcm
	}
	
	
	// MARK: - FHIRJSONType
	#if os(Linux)
	public typealias JSONType = Double
	#else
	public typealias JSONType = NSNumber
	#endif
	
	/**
	Initializer from the value the JSON parser returns.
	
	We're using a string format approach using "%.15g" since NSJSONFormatting returns NSNumber objects instantiated
	with Double() or Int(). In the former case this causes precision issues (e.g. try 8.7). Unfortunately, some
	doubles with 16 and 17 significant digits will be truncated (e.g. a longitude of "4.844614000123024").

	TODO: replace JSONSerialization with a different parser?
	*/
	public init(json: JSONType, owner: FHIRAbstractBase? = nil) throws {
		#if os(Linux)
		self.init(Decimal(json))
		#else
		if let _ = json.stringValue.characters.index(of: ".") {
			self.init(stringLiteral: String(format: "%.15g", json.doubleValue))
		}
		else {
			self.init(json.decimalValue)
		}
		#endif
		_owner = owner
	}
	
	public func asJSON(errors: inout [FHIRValidationError]) -> JSONType {
		#if os(Linux)
		return doubleValue
		#else
		return decimal as NSNumber
		#endif
	}
	
	
	// MARK: - LosslessStringConvertible & CustomStringConvertible
	
	public init?(_ description: String) {
		guard let dcm = Decimal(string: description) else {
			return nil
		}
		self.init(dcm)
	}
	
	public var description: String {
		return decimal.description
	}
	
	
	// MARK: - ExpressibleBy
	
	public init(stringLiteral string: StringLiteralType) {
		let dcm = Decimal(string: string)
		self.init(dcm ?? Decimal())
	}
	
	public init(unicodeScalarLiteral value: Character) {
		self.init(stringLiteral: "\(value)")
	}
	
	public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
		self.init(stringLiteral: value)
	}
	
	public init(booleanLiteral bool: Bool) {
		self.init(bool ? Decimal(1) : Decimal(0))
	}
	
	public init(integerLiteral integer: Int) {
		self.init(Decimal(integer))
	}
}

extension FHIRDecimal: Equatable, Comparable {
	
	public static func ==(l: FHIRDecimal, r: FHIRDecimal) -> Bool {
		return l.decimal == r.decimal
	}
	
	public static func ==(l: Decimal, r: FHIRDecimal) -> Bool {
		return l == r.decimal
	}
	
	public static func ==(l: FHIRDecimal, r: Decimal) -> Bool {
		return l.decimal == r
	}
	
	public static func ==(l: Double, r: FHIRDecimal) -> Bool {
		return Decimal(l) == r.decimal
	}
	
	public static func ==(l: FHIRDecimal, r: Double) -> Bool {
		return l.decimal == Decimal(r)
	}
	
	public static func ==(l: Int, r: FHIRDecimal) -> Bool {
		return Decimal(l) == r.decimal
	}
	
	public static func ==(l: FHIRDecimal, r: Int) -> Bool {
		return l.decimal == Decimal(r)
	}
	
	
	public static func <(lh: FHIRDecimal, rh: FHIRDecimal) -> Bool {
		return lh.decimal < rh.decimal
	}
	
	public static func <(lh: Decimal, rh: FHIRDecimal) -> Bool {
		return lh < rh.decimal
	}
	
	public static func <(lh: FHIRDecimal, rh: Decimal) -> Bool {
		return lh.decimal < rh
	}
	
	public static func <(lh: Double, rh: FHIRDecimal) -> Bool {
		return Decimal(lh) < rh.decimal
	}
	
	public static func <(lh: FHIRDecimal, rh: Double) -> Bool {
		return lh.decimal < Decimal(rh)
	}
	
	public static func <(lh: Int, rh: FHIRDecimal) -> Bool {
		return Decimal(lh) < rh.decimal
	}
	
	public static func <(lh: FHIRDecimal, rh: Int) -> Bool {
		return lh.decimal < Decimal(rh)
	}
}

