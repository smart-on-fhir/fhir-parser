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
	
	init(json: JSONType, owner: FHIRAbstractBase?) throws
	
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
	Represent the receiver in FHIRJSON, ready to be used for JSON serialization.
	
	- returns: The FHIRJSON reperesentation of the receiver
	*/
	func asJSON() throws -> JSONType
	
	func asJSON(errors: inout [FHIRValidationError]) -> JSONType
}

extension FHIRJSONType {
	
	public func asJSON() throws -> JSONType {
		var errors = [FHIRValidationError]()
		let json = asJSON(errors: &errors)
		if !errors.isEmpty {
			throw FHIRValidationError(errors: errors)
		}
		return json
	}
	
	public func populate(from json: FHIRJSON, presentKeys: inout Set<String>) throws -> [FHIRValidationError]? {
		return nil
	}
	
	public final func populate(from json: FHIRJSON) throws {
		var present = Set<String>()
		present.insert("fhir_comments")
		var errors = try populate(from: json, presentKeys: &present) ?? [FHIRValidationError]()
		
		// superfluous JSON entries? Ignore "fhir_comments".
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
			throw FHIRValidationError(key: key, wants: P.JSONType.self, has: type(of: exist))
		}
		var prim = try P(json: val, owner: owner)
		if let ext = json["_\(key)"] as? FHIRJSON {
			presentKeys.insert("_\(key)")
			try prim.populate(from: ext)
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
			var prim = try P(json: value, owner: owner)
			if primitiveExtensions?.count ?? 0 > i, let extended = primitiveExtensions?[i] {
				try prim.populate(from: extended)
			}
			primitives.append(prim)
		}
		catch let error as FHIRValidationError {
			errors.append(error.prefixed(with: "\(key).\(i)"))   // TODO: should prefix `_key` appropriately
		}
	}
	return primitives.isEmpty ? nil : primitives
}

// MARK: -


/**
Attempt to create an enum for the given key in the given dictionary, filling presentKeys and errors along the way.

- parameter type:   The enum type to create (as an array)
- parameter key:    The JSON key to look at in `json`
- parameter json:   The JSON dictionary to inspect
- parameter presentKeys: The keys in json found and handled
- parameter errors: Validation errors encountered are put into this array
- returns:          An array of enums, or nil
*/
public func createEnum<E: RawRepresentable>(type: E.Type, for key: String, in json: FHIRJSON, presentKeys: inout Set<String>, errors: inout [FHIRValidationError]) -> E? {
	guard let exist = json[key] else {
		return nil
	}
	presentKeys.insert(key)
	
	// correct type?
	guard let value = exist as? E.RawValue else {
		errors.append(FHIRValidationError(key: key, wants: E.RawValue.self, has: type(of: exist)))
		return nil
	}
	
	// create enum
	guard let enumval = E(rawValue: value) else {
		errors.append(FHIRValidationError(key: key, problem: "“\(value)” is not valid"))
		return nil
	}
	return enumval
}


/**
Attempt to create an array of enums for the given key in the given dictionary, populating presentKeys and errors appropriately.

- parameter type:   The enum type to create (as an array)
- parameter key:    The JSON key to look at in `json`
- parameter json:   The JSON dictionary to inspect
- parameter presentKeys: The keys in json found and handled
- parameter errors: Validation errors encountered are put into this array
- returns:          An array of enums, or nil
*/
public func createEnums<E: RawRepresentable>(of type: E.Type, for key: String, in json: FHIRJSON, presentKeys: inout Set<String>, errors: inout [FHIRValidationError]) -> [E]? {
	guard let exist = json[key] else {
		return nil
	}
	presentKeys.insert(key)
	
	// correct type?
	guard let val = exist as? [E.RawValue] else {
		errors.append(FHIRValidationError(key: key, wants: Array<E.RawValue>.self, has: type(of: exist)))
		return nil
	}
	
	// loop over raw values and create enums
	var enums = [E]()
	for (i, value) in val.enumerated() {
		guard let enumval = E(rawValue: value) else {
			errors.append(FHIRValidationError(key: "\(key).\(i)", problem: "“\(value)” is not valid"))
			continue
		}
		enums.append(enumval)
	}
	return enums
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

