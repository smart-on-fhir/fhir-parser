//
//  FHIRTypes.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 12/16/14.
//  2014, SMART Platforms.
//


/**
 *  A JSON dictionary, with `String` keys and `AnyObject` values.
 */
public typealias FHIRJSON = [String: AnyObject]


/**
 *  Data encoded as a base-64 string.
 */
public struct Base64Binary: Printable, Equatable, Comparable
{
	var value: String?
	
	public init(value: String) {
		self.value = value
	}
	
	
	// MARK: - Printable
	
	public var description: String {
		return "<Base64Binary; \(nil != value ? countElements(value!) : 0) chars>"
	}
}

public func <(lhs: Base64Binary, rhs: Base64Binary) -> Bool {
	return lhs.value < rhs.value
}

public func ==(lhs: Base64Binary, rhs: Base64Binary) -> Bool {
	return lhs.value == rhs.value
}

