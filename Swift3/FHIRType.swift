//
//  FHIRTypes.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 12/16/14.
//  2014, SMART Health IT.
//

import Foundation


/**
A JSON dictionary, with `String` keys and `Any` values.
*/
public typealias FHIRJSON = [String: Any]


/**
The base type for every FHIR element.
*/
public protocol FHIRType {
	
	/// The parent/owner of the receiver, if any. Used to dereference resources.
	var _owner: FHIRAbstractBase? { get set }
}


/**
A protocol to handle FHIRType when working with JSON - which in our case is all FHIR types.
*/
public protocol FHIRJSONType: FHIRType {
	
	/// The JSON element used to deserialize the receiver from and serialize to.
	associatedtype JSONType
	
	/**
	Generic initializer to be used on deserialized JSON.
	
	- parameter json:  The value in its associated `JSONType`
	- parameter owner: Optional, the owning element
	*/
	init(json: JSONType, owner: FHIRAbstractBase?) throws
	
	/**
	A static/class function that should return the correct (sub)type, depending on information found in `json`.
	
	On primitives, simply forwards to `init(json:owner:)`.
	
	- parameter json:  A JSONType instance from which to instantiate
	- parameter owner: The FHIRAbstractBase owning the new instance, if appropriate
	- returns:         If possible the appropriate FHIRAbstractBase subclass, instantiated from the given JSON dictionary, Self otherwise
	- throws:          FHIRValidationError
	*/
	static func instantiate(from json: JSONType, owner: FHIRAbstractBase?) throws -> Self
	
	/**
	Used during parsing, applies the values found in `json` (id and extension) to the receiver.
	
	- parameter json: The JSON dictionary to use to update the receiver
	*/
	mutating func populate(from json: FHIRJSON) throws
	
	/**
	The main function to perform the actual JSON parsing, to be overridden by subclasses.
	
	- parameter json:        The JSON element to use to populate the receiver
	- parameter presentKeys: An in-out parameter being filled with key names used.
	- returns:               An optional array of errors reporting missing mandatory keys or keys containing values of the wrong type
	- throws:                If anything besides a `FHIRValidationError` happens
	*/
	mutating func populate(from json: FHIRJSON, presentKeys: inout Set<String>) throws -> [FHIRValidationError]?
	
	/**
	Return the receiver's representation in `JSONType`.
	
	- parameter errors: Errors encountered during serialization
	- returns:          The FHIRJSON reperesentation of the receiver
	*/
	func asJSON(errors: inout [FHIRValidationError]) -> JSONType
	
	/**
	Represent the receiver in the given JSON dictionary.
	
	- note: Values that the instance alreay possesses and are not in the JSON should be left alone.
	
	- parameter json:    The FHIRJSON representation to populate
	- parameter withKey: The key to use
	- parameter errors:  An in-out array to be stuffed with validation errors encountered along the way
	*/
	func decorate(json: inout FHIRJSON, withKey: String, errors: inout [FHIRValidationError])
}

extension FHIRJSONType {
	
	public func populate(from json: FHIRJSON, presentKeys: inout Set<String>) throws -> [FHIRValidationError]? {
		return nil
	}
	
	public final func populate(from json: FHIRJSON) throws {
		var present = Set<String>()
		present.insert("fhir_comments")
		var errors = try populate(from: json, presentKeys: &present) ?? [FHIRValidationError]()
		
		// superfluous JSON entries?
		let superfluous = json.keys.filter() { !present.contains($0) }
		if !superfluous.isEmpty {
			for sup in superfluous {
				errors.append(FHIRValidationError(unknown: sup, ofType: type(of: json[sup]!)))
			}
		}
		
		if !errors.isEmpty {
			if nil == _owner {
				errors = errors.map() { $0.prefixed(with: "\(type(of: self))") }
			}
			throw FHIRValidationError(errors: errors)
		}
	}
}

// MARK: -


/**
Inspects the given dictionary for the value of the given key, then instantiates the desired type if possible.

Cannot implement this as `init?() throws` because it needs to inspect `P.JSONType` before calling `init()`, which is not possible.

- parameter type:   The primitive type that is wanted
- parameter key:    The key for which to look in `json`
- parameter json:   The JSON dictionary to search through
- parameter presentKeys: An inout set of keys found and handled in the JSON
- parameter errors: An inout array of validation errors observed
- parameter owner:  The FHIRAbstractBase owning the new instance, if appropriate
- returns:          An instance of the appropriate FHIRPrimitive, or nil
*/
public func createInstance<P: FHIRJSONType>(type: P.Type, for key: String, in json: FHIRJSON, presentKeys: inout Set<String>, errors: inout [FHIRValidationError], owner: FHIRAbstractBase?) throws -> P? {
	guard let exist = json[key] else {
		return nil
	}
	presentKeys.insert(key)
	
	do {
		guard let val = exist as? P.JSONType else {
			throw FHIRValidationError(key: "", wants: P.JSONType.self, has: type(of: exist))
		}
		var prim = try P.instantiate(from: val, owner: owner)
		if let ext = json["_\(key)"] as? FHIRJSON {
			presentKeys.insert("_\(key)")
			try prim.populate(from: ext, presentKeys: &presentKeys)?.forEach() { errors.append($0) }
		}
		return prim
	}
	catch let error as FHIRValidationError {
		errors.append(error.prefixed(with: key))
	}
	return nil
}


/**
Inspects the given dictionary for an array with the given key, and if successful instantiates an array of the desired types.

This method cannot be part of FHIRJSONType because it would have to be implemented by every resource class, instead of just the
base class (error is "Protocol requirement cannot be satisfied by non-final class because it uses 'Self' in a non-parameter,
non-result type position).

- parameter type:   The primitive type that is expected
- parameter key:    The key for which to look in `json`
- parameter json:   The JSON dictionary to search through
- parameter presentKeys: An inout set of keys found in the JSON
- parameter errors: An inout array of validation errors found
- parameter owner:  The FHIRAbstractBase owning the new instance, if appropriate
- returns:          An array of the appropriate FHIRPrimitive, or nil
*/
public func createInstances<P: FHIRJSONType>(of type: P.Type, for key: String, in json: FHIRJSON, presentKeys: inout Set<String>, errors: inout [FHIRValidationError], owner: FHIRAbstractBase?) throws -> [P]? {
	guard let exist = json[key] else {
		return nil
	}
	presentKeys.insert(key)
	
	// correct type, also for _key?
	guard let val = exist as? [P.JSONType] else {
		errors.append(FHIRValidationError(key: key, wants: Array<P.JSONType>.self, has: type(of: exist)))
		return nil
	}
	var primitiveExtensions: [FHIRJSON?]?
	if let primitivesExist = json["_\(key)"] {
		presentKeys.insert("_\(key)")
		if let primitivesCorrect = primitivesExist as? [FHIRJSON?] {
			primitiveExtensions = primitivesCorrect
		}
		else {
			errors.append(FHIRValidationError(key: "_\(key)", wants: Array<FHIRJSON?>.self, has: type(of: primitivesExist)))
		}
	}
	
	// instantiate primitives including extensions
	var primitives = [P]()
	for (i, value) in val.enumerated() {
		do {
			var prim = try P.instantiate(from: value, owner: owner)
			if primitiveExtensions?.count ?? 0 > i, let extended = primitiveExtensions?[i] {
				try prim.populate(from: extended, presentKeys: &presentKeys)?.forEach() { errors.append($0) }
			}
			primitives.append(prim)
		}
		catch let error as FHIRValidationError {
			errors.append(error.prefixed(with: "\(key).\(i)"))   // TODO: should prefix `_key` appropriately
		}
	}
	return primitives.isEmpty ? nil : primitives
}


// MARK: - Helper Functions

extension String {
	/**
	Convenience getter using `NSLocalizedString()` with no comment.
	
	TODO: On Linux this currently simply returns self
	*/
	public var fhir_localized: String {
		#if os(Linux)
		return self
		#else
		return NSLocalizedString(self, comment: "")
		#endif
	}
}

/**
Execute a `print()`, prepending filename, line and function/method name, if `DEBUG` is defined.
*/
public func fhir_logIfDebug(_ message: @autoclosure () -> String, function: String = #function, file: String = #file, line: Int = #line) {
#if DEBUG
	print("SwiftFHIR [\(URL(fileURLWithPath: file).lastPathComponent):\(line)] \(function)  \(message())")
#endif
}

/**
Execute a `print()`, prepending filename, line and function/method name and "WARNING" prepended.
*/
public func fhir_warn(_ message: @autoclosure () -> String, function: String = #function, file: String = #file, line: Int = #line) {
	print("SwiftFHIR [\(URL(fileURLWithPath: file).lastPathComponent):\(line)] \(function)  WARNING: \(message())")
}

