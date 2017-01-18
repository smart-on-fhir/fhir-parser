//
//  FHIRURL.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 06.12.16.
//  2016, SMART Health IT.
//

import Foundation


/**
Struct to hold on to URLs.
*/
public struct FHIRURL: FHIRPrimitive, CustomStringConvertible {
	
	/// The actual url.
	public var url: URL
	
	/// An optional id of the element.
	public var id: String?
	
	/// The parent/owner of the receiver, if any. Used to dereference resources.
	public weak var _owner: FHIRAbstractBase?
	
	/// Optional extensions of the element.
	public var extension_fhir: [Extension]?
	
	/// Returns true if the string is the empty string.
	public var absoluteString: String {
		return url.absoluteString
	}
	
	
	/**
	Designated initializer.
	
	- parameter string: The URL represented by the receiver
	*/
	public init(_ url: URL) {
		self.url = url
	}
	
	/**
	Convenience initializer.
	
	- parameter string: The URL string represented by the receiver
	*/
	public init?(_ string: String) {
		guard let url = URL(string: string) else {
			return nil
		}
		self.init(url)
	}
	
	
	// MARK: - FHIRJSONType
	
	public typealias JSONType = String
	
	public init(json: JSONType, owner: FHIRAbstractBase? = nil) throws {
		guard let url = URL(string: json) else {
			throw FHIRValidationError(key: "", problem: "“\(json)” is not a valid URI")
		}
		self.url = url
		_owner = owner
	}
	
	public func asJSON(errors: inout [FHIRValidationError]) -> JSONType {
		return url.absoluteString
	}
	
	
	// MARK: - CustomStringConvertible
	
	public var description: String {
		return url.description
	}
}


extension URL {
	
	public var absoluteFHIRString: FHIRString {
		return FHIRString(absoluteString)
	}
	
	/// Convert the receiver to `FHIRURL`. This is particularly useful when dealing with optional URLs.
	public var fhir_url: FHIRURL {
		return FHIRURL(self)
	}
}

