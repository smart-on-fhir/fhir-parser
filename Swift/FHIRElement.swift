//
//  FHIRElement.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 7/2/14.
//  2014, SMART Health IT.
//


/**
 *  Abstract superclass for all FHIR data elements.
 */
public class FHIRElement: CustomStringConvertible
{
	/// The name of the resource or element
	public class var resourceName: String {
		get { return "Element" }
	}
	
	/// Logical id of this artefact
	public var id: String?
	
	/// Contained, inline Resources, indexed by resource id.
	public var contained: [String: FHIRContainedResource]?
	
	/// The parent/owner of the receiver, if any. Used to dereference resources.
	weak var _owner: FHIRElement?
	
	/// Resolved references.
	var _resolved: [String: Resource]?
	
	/// Additional Content defined by implementations
	public var extension_fhir: [Extension]?
	
	/// Extensions that cannot be ignored
	public var modifierExtension: [Extension]?
	
	
	/**
		The default initializer.
		
		Forwards to `populateFromJSON` and logs all JSON errors to console, if "DEBUG" is defined and true.
	 */
	public required init(json: FHIRJSON?) {
		if let errors = populateFromJSON(json) {
			for error in errors {
				fhir_logIfDebug(error.description)
			}
		}
	}
	
	
	// MARK: - JSON Capabilities
	
	/**
		Will populate instance variables - overriding existing ones - with values found in the supplied JSON.
		
		- parameter json: The JSON dictionary to pull data from
		- returns: An optional array of errors reporting missing (when nonoptional) and superfluous properties and
			properties of the wrong type
	 */
	public final func populateFromJSON(json: FHIRJSON?) -> [FHIRJSONError]? {
		var present = Set<String>()
		var errors = populateFromJSON(json, presentKeys: &present) ?? [FHIRJSONError]()
		
		// superfluous JSON entries?
		let superfluous = json?.keys.array.filter() { !present.contains($0) }
		if let supflu = superfluous where !supflu.isEmpty {
			for sup in supflu {
				errors.append(FHIRJSONError(key: sup, has: json![sup]!.dynamicType))
			}
		}
		return errors.isEmpty ? nil : errors
	}
	
	/**
		Internal function to perform the actual JSON parsing.
 
		- parameter json: The JSON element to use to populate the receiver
		- parameter presentKeys: An in-out parameter being filled with key names used.
		- returns: An optional array of errors reporting missing mandatory keys or keys containing values of the wrong type
	 */
	func populateFromJSON(json: FHIRJSON?, inout presentKeys: Set<String>) -> [FHIRJSONError]? {
		if let js = json {
			var errors = [FHIRJSONError]()
			
			if let exist: AnyObject = js["id"] {
				presentKeys.insert("id")
				if let val = exist as? String {
					id = val
				}
				else {
					String.Type.self
					errors.append(FHIRJSONError(key: "id", wants: String.self, has: exist.dynamicType))
				}
			}
			
			// extract contained resources
			if let exist: AnyObject = js["contained"] {
				presentKeys.insert("contained")
				if let arr = exist as? [FHIRJSON] {
					var cont = contained ?? [String: FHIRContainedResource]()
					for dict in arr {
						let res = FHIRContainedResource(json: dict, owner: self)
						if let res_id = res.id {
							cont[res_id] = res
						}
						else {
							print("Contained resource in \(self) without “id” will be ignored")
						}
					}
					contained = cont
				}
				else {
					errors.append(FHIRJSONError(key: "contained", wants: Array<FHIRJSON>.self, has: exist.dynamicType))
				}
			}
			
			// instantiate (modifier-)extensions
			if let exist: AnyObject = js["extension"] {
				presentKeys.insert("extension")
				if let val = exist as? [FHIRJSON] {
					extension_fhir = Extension.from(val, owner: self) as? [Extension]
				}
				else {
					errors.append(FHIRJSONError(key: "extension", wants: Array<FHIRJSON>.self, has: exist.dynamicType))
				}
			}
			if let exist: AnyObject = js["modifierExtension"] {
				presentKeys.insert("modifierExtension")
				if let val = exist as? [FHIRJSON] {
					modifierExtension = Extension.from(val, owner: self) as? [Extension]
				}
				else {
					errors.append(FHIRJSONError(key: "modifierExtension", wants: Array<FHIRJSON>.self, has: exist.dynamicType))
				}
			}
			return errors.isEmpty ? nil : errors
		}
		return nil
	}
	
	/**
		Represent the receiver in FHIRJSON, ready to be used for JSON serialization.
	 */
	public func asJSON() -> FHIRJSON {
		var json = FHIRJSON()
		//json["resourceType"] = self.dynamicType.resourceName		// we only do this for resources
		
		if let id = self.id {
			json["id"] = id.asJSON()
		}
		if let contained = self.contained {
			var arr = [FHIRJSON]()
			for (key, cont) in contained {
				let refid = cont.id ?? key
				let resolved = resolvedReference(refid)
				var json = resolved?.asJSON() ?? cont.json ?? FHIRJSON()
				json["id"] = refid
				arr.append(json)
			}
			json["contained"] = arr
		}
		if let extension_fhir = self.extension_fhir {
			json["extension"] = Extension.asJSONArray(extension_fhir)
		}
		if let modifierExtension = self.modifierExtension {
			json["modifierExtension"] = Extension.asJSONArray(modifierExtension)
		}
		
		return json
	}
	
	/**
		Calls `asJSON()` on all elements in the array and returns the resulting array full of FHIRJSON dictionaries.
	 */
	public class func asJSONArray(array: [FHIRElement]) -> [FHIRJSON] {
		var arr = [FHIRJSON]()
		for element in array {
			arr.append(element.asJSON())
		}
		return arr
	}
	
	/**
		Convenience allocator to be used when allocating an element as part of another element.
	 */
	public convenience init(json: FHIRJSON?, owner: FHIRElement?) {
		self.init(json: json)
		self._owner = owner
	}
	
	
	// MARK: - Factories
	
	/**
		Tries to find `resourceType` by inspecting the JSON dictionary, then instantiates the appropriate class for the
		specified resource type, or instantiates the receiver's class otherwise.
		
		- parameter json: A FHIRJSON decoded from a JSON response
		- parameter owner: The FHIRElement owning the new instance, if appropriate
		- returns: If possible the appropriate FHIRElement subclass, instantiated from the given JSON dictionary, Self otherwise
	 */
	public final class func instantiateFrom(json: FHIRJSON?, owner: FHIRElement?) -> FHIRElement {
		if let type = json?["resourceType"] as? String {
			return factory(type, json: json!, owner: owner)
		}
		let instance = self.init(json: json)		// must use 'required' init with dynamic type
		instance._owner = owner
		return instance
	}
	
	/**
		Instantiates an array of the receiver's type and returns it.
		TODO: Returning [Self] is not yet possible (Swift 1.2), too bad
	 */
	public final class func from(array: [FHIRJSON]) -> [FHIRElement] {
		var arr = [FHIRElement]()
		for arrJSON in array {
			arr.append(self.init(json: arrJSON))
		}
		return arr
	}
	
	/**
		Instantiates an array of the receiver's type and returns it.
	 */
	public final class func from(array: [FHIRJSON], owner: FHIRElement?) -> [FHIRElement] {
		let arr = from(array)
		for elem in arr {
			elem._owner = owner			// would be neater to use init(json:owner:) but cannot use non-required init with dynamic type
		}
		return arr
	}
	
	
	// MARK: - Contained Resources
	
	/** Returns the contained reference with the given id, if it exists. */
	func containedReference(refid: String) -> FHIRContainedResource? {
		if let cont = contained?[refid] {
			return cont
		}
		return _owner?.containedReference(refid)
	}
	
	/**
	Contains the given contained resource instance and returns the Reference element on success.
	
	:param containedResource: The instance to add to the `contained` dictionary
	- returns: A `Reference` instance if containment was successful
	*/
	func containReference(containedResource: FHIRContainedResource) -> Reference? {
		if let refid = containedResource.id where !refid.isEmpty {
			var cont = contained ?? [String: FHIRContainedResource]()
			cont[refid] = containedResource
			contained = cont
			
			let ref = Reference(json: nil, owner: self)
			ref.reference = "#\(refid)"
			return ref
		}
		fhir_logIfDebug("cannot contain a FHIRContainedResource without a non-empty id, have: \(containedResource)")
		return nil
	}
	
	/**
	Embeds the given resource as a contained resource with the given id.
	
	:param resource: The resource to contain
	:param withId: The id to use as internal reference
	- returns: A `Reference` instance if containment was successful
	*/
	public func containResource(resource: Resource, withId: String) -> Reference? {
		if !withId.isEmpty {
			let contRes = FHIRContainedResource(id: withId, json: resource.asJSON(), owner: self)
			if let ref = containReference(contRes) {
				resource._owner = self
				didResolveReference(withId, resolved: resource)
				return ref
			}
		}
		fhir_logIfDebug("cannot contain a Resource with an empty id")
		return nil
	}
	
	
	// MARK: - Resolving References
	
	/** Returns the resolved reference with the given id, if it has been resolved already. */
	func resolvedReference(refid: String) -> Resource? {
		if let resolved = _resolved?[refid] {
			return resolved
		}
		return _owner?.resolvedReference(refid)
	}
	
	/**
		Stores the resolved reference into the `_resolved` dictionary.
	
		- parameter refid: The reference identifier as String
		- parameter resolved: The element that was resolved
	 */
	func didResolveReference(refid: String, resolved: Resource) {
		if nil != _resolved {
			_resolved![refid] = resolved
		}
		else {
			_resolved = [refid: resolved]
		}
	}
	
	/**
		The resource owning the receiver; used during reference resolving and to look up the instance's `_server`, if any.
	 */
	func owningResource() -> FHIRResource? {
		var owner = _owner
		while nil != owner {
			if nil != owner as? FHIRResource {
				break
			}
			owner = owner?._owner
		}
		return owner as? FHIRResource
	}
	
	
	// MARK: - Printable
	
	public var description: String {
		return "<\(self.dynamicType.resourceName)>"
	}
}

