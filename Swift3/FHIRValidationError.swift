//
//  FHIRError.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 11/24/15.
//  2015, SMART Health IT.
//

import Foundation


/**
The type of the validation error.
*/
public enum FHIRValidationErrorType: Int {
	
	/// The key is mandatory but missing.
	case missingKey
	
	/// This property key should not be here.
	case unknownKey
	
	/// The value type for the key is wrong.
	case wrongValueTypeForKey
	
	/// A problem with the value of the key that is described in text.
	case problemWithValueForKey
	
	/// Errors of this type usually encapsulate child validation errors.
	case problemsWithKey
}


/**
Errors thrown during serialization and deserialization.
*/
public struct FHIRValidationError: Error, CustomStringConvertible {
	
	/// The error type.
	public var code: FHIRValidationErrorType
	
	/// The property key to which the error applies; may be empty for errors raised by primitives.
	public var key: String
	
	/// The path to the key, excluding the key itself.
	public var path: String?
	
	/// The full path to the property.
	public var fullPath: String {
		return (nil == path || path!.isEmpty) ? key : (key.isEmpty ? path! : "\(path!).\(key)")
	}
	
	/// The type expected for values of this key.
	public var wants: Any.Type?
	
	/// The type received for this key.
	public var has: Any.Type?
	
	/// A problem description.
	public var problem: String?
	
	/// Sub-errors.
	public var subErrors: [FHIRValidationError]?
	
	
	/** Designated initializer.
	
	- parameter code: The type of validation error described by the instance
	- parameter key:  The key to which the error applies
	*/
	init(code: FHIRValidationErrorType, key: String) {
		self.code = code
		self.key = key
	}
	
	/** Initializer to use when a given key is missing.
	
	- parameter key: The missing key
	*/
	public init(missing key: String) {
		self.init(code: .missingKey, key: key)
	}
	
	/** Initializer to use when a given key is present but is not expected.
	
	- parameter key:  The unknown key
	- parameter type: The type of the object associated with the unknown key
	*/
	public init(unknown key: String, ofType type: Any.Type) {
		self.init(code: .unknownKey, key: key)
		self.has = type
	}
	
	/** Initializer to use when there is a problem with a given key (other than the key missing or being unknown).
	
	- parameter key:     The problematic key
	- parameter problem: A description of the problem
	*/
	public init(key: String, problem: String) {
		self.init(code: .problemWithValueForKey, key: key)
		self.problem = problem
	}
	
	/** Initializer to use when the value of the given key is of a wrong type.
	
	- parameter key:   The key for which there is a type mismatch
	- parameter wants: The type expected for the key
	- parameter has:   The (wrong) type received for the key
	*/
	public init(key: String, wants: Any.Type, has: Any.Type) {
		self.init(code: .wrongValueTypeForKey, key: key)
		self.wants = wants
		self.has = has
	}
	
	/** Initializer to use for a validation error containing child errors. The `key` will be set to an empty string, the parent
	will need to fill this value.
	
	- parameter errors: The errors to contain
	*/
	public init(errors: [FHIRValidationError]) {
		self.init(code: .problemsWithKey, key: "")
		self.subErrors = errors
	}
	
	
	// MARK: - Nesting Errors
	
	public func prefixed(with prefix: String) -> FHIRValidationError {
		var prefixed = self
		if key.isEmpty {
			prefixed.key = prefix
		}
		else if nil == path || path!.isEmpty {
			prefixed.path = prefix.isEmpty ? nil : prefix
		}
		else {
			prefixed.path = prefix.isEmpty ? path : "\(prefix).\(path!)"
		}
		return prefixed
	}
	
	
	// MARK: - CustomStringConvertible
	
	public var description: String {
		let nul = Any.self
		let prop = key.isEmpty ? "" : " “\(key)”"
		switch code {
		case .missingKey:
			return "\(fullPath): mandatory property\(prop) is missing"
		case .unknownKey:
			return "\(fullPath): superfluous property\(prop) of type `\(has ?? nul)`"
		case .wrongValueTypeForKey:
			return "\(fullPath): expecting property\(prop) to be `\(wants ?? nul)`, but is `\(has ?? nul)`"
		case .problemWithValueForKey:
			return "\(fullPath): problem with property\(prop): \(problem ?? "[problem not described]")"
		case .problemsWithKey:
			guard let subErrors = subErrors else {
				return "\(fullPath): [no errors]"
			}
			return subErrors.map { (fullPath.isEmpty ? $0 : $0.prefixed(with: fullPath)).description }.joined(separator: "\n")
		}
	}
}

