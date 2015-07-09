//
//  FHIRElement.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 7/2/14.
//  2014, SMART Health IT.
//

import Foundation


/**
 *  Abstract superclass for all FHIR data elements.
 */
public class FHIRElement: Printable
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
				fhir_logIfDebug(error.localizedDescription)
			}
		}
	}
	
	
	// MARK: - JSON Capabilities
	
	/**
		Will populate instance variables - overriding existing ones - with values found in the supplied JSON.
		
		:param: json The JSON dictionary to pull data from
		:returns: An optional array of errors reporting missing (when nonoptional) and superfluous properties and
			properties of the wrong type
	 */
	public final func populateFromJSON(json: FHIRJSON?) -> [NSError]? {
		let present = NSMutableSet()
		var errors = populateFromJSON(json, presentKeys: present) ?? [NSError]()
		
		// superfluous JSON entries?
		let superfluous = json?.keys.array.filter() { !present.containsObject($0) }
		if let supflu = superfluous where !supflu.isEmpty {
			for sup in supflu {
				errors.append(fhir_generateJSONError("\(self) has superfluous JSON property “\(sup)”, ignoring"))
			}
		}
		return errors.isEmpty ? nil : errors
	}
	
	/**
		Internal function to perform the actual JSON parsing and pass used key information from sub to superclass.
	 */
	func populateFromJSON(json: FHIRJSON?, presentKeys: NSMutableSet) -> [NSError]? {
		if let js = json {
			var errors = [NSError]()
			
			if let exist: AnyObject = js["id"] {
				presentKeys.addObject("id")
				if let val = exist as? String {
					id = val
				}
				else {
					errors.append(fhir_generateJSONError("\(self) expects JSON property “id” to be `String`, but is \(exist.dynamicType)"))
				}
			}
			
			// extract contained resources
			if let exist: AnyObject = js["contained"] {
				presentKeys.addObject("contained")
				if let arr = exist as? [FHIRJSON] {
					var cont = contained ?? [String: FHIRContainedResource]()
					for dict in arr {
						let res = FHIRContainedResource(json: dict, owner: self)
						if let res_id = res.id {
							cont[res_id] = res
						}
						else {
							println("Contained resource in \(self) without “id” will be ignored")
						}
					}
					contained = cont
				}
				else {
					errors.append(fhir_generateJSONError("\(self) expects JSON property “contained” to be an array of `FHIRJSON`, but is \(exist.dynamicType)"))
				}
			}
			
			// instantiate (modifier-)extensions
			if let exist: AnyObject = js["extension"] {
				presentKeys.addObject("extension")
				if let val = exist as? [FHIRJSON] {
					extension_fhir = Extension.from(val, owner: self) as? [Extension]
				}
				else {
					errors.append(fhir_generateJSONError("\(self) expects JSON property “extension” to be an array of `FHIRJSON`, but is \(exist.dynamicType)"))
				}
			}
			if let exist: AnyObject = js["modifierExtension"] {
				presentKeys.addObject("modifierExtension")
				if let val = exist as? [FHIRJSON] {
					modifierExtension = Extension.from(val, owner: self) as? [Extension]
				}
				else {
					errors.append(fhir_generateJSONError("\(self) expects JSON property “modifierExtension” to be an array of `FHIRJSON`, but is \(exist.dynamicType)"))
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
				var resolved = resolvedReference(refid)
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
		
		:param: json A FHIRJSON decoded from a JSON response
		:param: owner The FHIRElement owning the new instance, if appropriate
		:returns: If possible the appropriate FHIRElement subclass, instantiated from the given JSON dictionary, Self otherwise
	 */
	public final class func instantiateFrom(json: FHIRJSON?, owner: FHIRElement?) -> FHIRElement {
		if let type = json?["resourceType"] as? String {
			return factory(type, json: json!, owner: owner)
		}
		let instance = self(json: json)		// must use 'required' init with dynamic type
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
			arr.append(self(json: arrJSON))
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
	:returns: A `Reference` instance if containment was successful
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
	:returns: A `Reference` instance if containment was successful
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
	
		:param: refid The reference identifier as String
		:param: resolved The element that was resolved
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

