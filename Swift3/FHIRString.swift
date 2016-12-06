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
public struct FHIRString: CustomStringConvertible, ExpressibleByStringLiteral {
	
	/// The actual string value.
	public var string: String
	
	/**
	Designated initializer.
	*/
	public init(_ string: String) {
		self.string = string
	}
	
	public var isEmpty: Bool {
		return string.isEmpty
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

