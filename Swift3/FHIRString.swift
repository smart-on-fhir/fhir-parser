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
	
	
	// MARK: - ExpressibleByStringLiteral
	
	public init(stringLiteral value: String) {
		self.init(value)
	}
	
	public init(unicodeScalarLiteral value: String) {
		self.init(value)
	}
	
	public init(extendedGraphemeClusterLiteral value: String) {
		self.init(value)
	}
	
	
	// MARK: - CustomStringConvertible
	
	public var description: String {
		return string
	}
}


extension FHIRString: Equatable {
	
	static public func ==(l: FHIRString, r: FHIRString) -> Bool {
		return l.string == r.string
	}
	
	static public func ==(l: String, r: FHIRString) -> Bool {
		return l == r.string
	}
	
	static public func ==(l: FHIRString, r: String) -> Bool {
		return l.string == r
	}
}


extension URL {
	
	public var absoluteFHIRString: FHIRString {
		return FHIRString(absoluteString)
	}
}

