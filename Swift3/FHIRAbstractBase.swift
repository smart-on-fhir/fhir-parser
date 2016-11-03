//
//  FHIRAbstractBase.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 7/2/14.
//  2014, SMART Health IT.
//


/**
Abstract superclass for all FHIR data elements.
*/
open class FHIRAbstractBase: CustomStringConvertible {
	
	/// The type of the resource or element.
	open class var resourceType: String {
		get { return "FHIRAbstractBase" }
	}
	
	/// The parent/owner of the receiver, if any. Used to dereference resources.
	weak var _owner: FHIRAbstractBase?
	
	/// Resolved references.
	var _resolved: [String: Resource]?
	
	
	/**
	The default initializer, made “required” so instantiation with a metatype is possible.
	
	Forwards to `populate(from:)`.
	
	- parameter json:  The JSON element to use to populate the receiver
	- parameter owner: If the receiver is an element or a resource in another resource, this references that "owner"
	*/
	public required init(json: FHIRJSON, owner: FHIRAbstractBase? = nil) throws {
		_owner = owner
		try populate(from: json)
	}
	
	/**
	Basic initializer for easy construction of new instances in code.
	
	- parameter owner: An optional owner of the element or resource
	*/
	public init(owner: FHIRAbstractBase? = nil) {
		_owner = owner
	}
	
	
	// MARK: - JSON Capabilities
	
	/**
	Will populate instance variables - overriding existing ones - with values found in the supplied JSON.
	
	- parameter json: The JSON element to use to populate the receiver
	- returns:        An optional array of errors reporting missing (when nonoptional) and superfluous properties and properties of the
	                  wrong type
	- throws:         FHIRValidationError (it's theoretically possible that it throws something else)
	*/
	public final func populate(from json: FHIRJSON) throws {
		var present = Set<String>()
		present.insert("fhir_comments")
		var errors = try populate(from: json, presentKeys: &present) ?? [FHIRValidationError]()
		
		// superfluous JSON entries? Ignore "fhir_comments" and "_xy".
		let superfluous = json.keys.filter() { !present.contains($0) }
		if !superfluous.isEmpty {
			for sup in superfluous {
				if let first = sup.characters.first, "_" != first {
					errors.append(FHIRValidationError(unknown: sup, ofType: type(of: json[sup]!)))
				}
			}
		}
		
		if !errors.isEmpty {
			if nil == _owner {
				errors = errors.map() { $0.prefixed(with: type(of: self).resourceType) }
			}
			if 1 == errors.count {
				throw errors[0]
			}
			throw FHIRValidationError(errors: errors)
		}
	}
	
	/**
	The main function to perform the actual JSON parsing, to be overridden by subclasses.
	 
	- parameter json:        The JSON element to use to populate the receiver
	- parameter presentKeys: An in-out parameter being filled with key names used.
	- returns:               An optional array of errors reporting missing mandatory keys or keys containing values of the wrong type
	- throws:                If anything besides a `FHIRValidationError` happens
	*/
	open func populate(from json: FHIRJSON, presentKeys: inout Set<String>) throws -> [FHIRValidationError]? {
		return nil
	}
	
	/**
	Represent the receiver in FHIRJSON, ready to be used for JSON serialization.
	
	- returns: The FHIRJSON reperesentation of the receiver
	*/
	public final func asJSON() throws -> FHIRJSON {
		var errors = [FHIRValidationError]()
		let json = asJSON(errors: &errors)
		if !errors.isEmpty {
			// TODO: concat errors
			throw errors[0]
		}
		return json
	}
	
	/**
	Represent the receiver in FHIRJSON, ready to be used for JSON serialization. Non-throwing version that you can use if
	you want to handle errors yourself or ignore them altogether. Otherwise, just use `asJSON() throws`.
	
	- parameter errors: The array that will be filled with FHIRValidationError instances, if there are any
	- returns: The FHIRJSON reperesentation of the receiver
	*/
	open func asJSON(errors: inout [FHIRValidationError]) -> FHIRJSON {
		return FHIRJSON()
	}
	
	
	// MARK: - Factories
	
	/**
	Tries to find `resourceType` by inspecting the JSON dictionary, then instantiates the appropriate class for the
	specified resource type, or instantiates the receiver's class otherwise.
	
	- parameter json:  A FHIRJSON decoded from a JSON response
	- parameter owner: The FHIRAbstractBase owning the new instance, if appropriate
	- returns:         If possible the appropriate FHIRAbstractBase subclass, instantiated from the given JSON dictionary, Self otherwise
	- throws:          FHIRValidationError
	*/
	public final class func instantiate(from json: FHIRJSON, owner: FHIRAbstractBase?) throws -> FHIRAbstractBase {
		if let type = json["resourceType"] as? String {
			return try factory(type, json: json, owner: owner)
		}
		return try self.init(json: json, owner: owner)		// must use 'required' init with dynamic type
	}
	
	/**
	Instantiates an array of the receiver's type and returns it.
	
	- parameter fromArray: The FHIRJSON array to instantiate from
	- parameter owner:     The FHIRAbstractBase owning the new instance, if appropriate
	- returns:             An array of the appropriate FHIRAbstractBase subclass, if possible, Self otherwise
	*/
	public final class func instantiate(fromArray: [FHIRJSON], owner: FHIRAbstractBase? = nil) throws -> [FHIRAbstractBase] {
		var instances = [FHIRAbstractBase]()
		var errors = [FHIRValidationError]()
		var i = 0
		for json in fromArray {
			do {
				let instance = try instantiate(from: json, owner: owner)
				instances.append(instance)
			}
			catch let error as FHIRValidationError {
				errors.append(error.prefixed(with: "\(i)"))
			}
			i += 1
		}
		if !errors.isEmpty {
			throw FHIRValidationError(errors: errors)
		}
		return instances
	}
	
	
	// MARK: - Resolving References
	
	/** Returns the resolved reference with the given id, if it has been resolved already. */
	public func resolvedReference(_ refid: String) -> Resource? {
		if let resolved = _resolved?[refid] {
			return resolved
		}
		return _owner?.resolvedReference(refid)
	}
	
	/**
	Stores the resolved reference into the `_resolved` dictionary.
	
	This method is public because it's used in an extension in our client. You likely don't need to use it explicitly, use the
	`resolve(type:callback:)` method on `Reference` instead.
	
	- parameter refid: The reference identifier as String
	- parameter resolved: The resource that was resolved
	*/
	public func didResolveReference(_ refid: String, resolved: Resource) {
		if nil != _resolved {
			_resolved![refid] = resolved
		}
		else {
			_resolved = [refid: resolved]
		}
	}
	
	/**
	The resource owning the receiver; used during reference resolving and to look up the instance's `_server`, if any.
	
	- returns: The owning `DomainResource` instance or nil
	*/
	open var owningResource: DomainResource? {
		var owner = _owner
		while nil != owner {
			if let owner = owner as? DomainResource {
				return owner
			}
			owner = owner?._owner
		}
		return nil
	}
	
	/**
	Returns the receiver's owning Bundle, if it has one.
	
	- returns: The owning `Bundle` instance or nil
	*/
	open var owningBundle: Bundle? {
		var owner = _owner
		while nil != owner {
			if let owner = owner as? Bundle {
				return owner
			}
			owner = owner?._owner
		}
		return nil
	}
	
	
	// MARK: - CustomStringConvertible
	
	open var description: String {
		return "<\(type(of: self).resourceType)>"
	}
}

