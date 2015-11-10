//
//  FHIRElement.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 7/2/14.
//  2014, SMART Health IT.
//


/**
 *  Information about an element property.
 */
public struct FHIRElementPropertyDefn {
	
	/// The name of the property.
	public var name: String
	
	/// The name of the property in JSON serialization.
	public var jsonName: String
	
	/// The type of the property.
	public var type: Any.Type
	
	/// Whether the property is an array.
	public var isArray = false
	
	/// Whether the property cannot be null/empty.
	public var mandatory = false
	
	/// Whether the property is one of several different properties of different type (e.g. valueBool, valueQuantity -> value)
	public var oneOfMany: String? = nil
}


/**
 *  Abstract superclass for all FHIR data elements.
 */
public class FHIRElement: FHIRJSONConvertible, CustomStringConvertible {
	
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
	
	
	// MARK: - Properties
	
	var _lastSubscriptSetterError: FHIRJSONError?	// TODO: subscripts currently (Swift 2.1) are not throwable. Cheat by using this ivar
	
	public subscript(name: String) -> FHIRJSONConvertible? {
		get {
			switch name {
			case "id":
				return id?.asJSON()
			case "contained":
				if let contained = self.contained {
					var arr = [FHIRJSON]()
					for (key, cont) in contained {
						let refid = cont.id ?? key
						let resolved = resolvedReference(refid)
						var json = resolved?.asJSON() ?? cont.json ?? FHIRJSON()
						json["id"] = refid
						arr.append(json)
					}
					return arr
				}
				return nil
			case "extension":
				return extension_fhir?.asJSON()
			case "modifierExtension":
				return modifierExtension?.asJSON()
			default:
				return nil
			}
		}
		set(newValue) {
			switch name {
			case "id":
				guard let val = newValue where val is String else {
					_lastSubscriptSetterError = FHIRJSONError(key: "id", wants: String.self, has: newValue.dynamicType)
					self.id = nil
					return
				}
				self.id = (val as! String)
			case "contained":
				guard let val = newValue where val is [String: FHIRContainedResource] else {
					_lastSubscriptSetterError = FHIRJSONError(key: "contained", wants: [String: FHIRContainedResource].self, has: newValue.dynamicType)
					self.contained = nil
					return
				}
				self.contained = (val as! [String: FHIRContainedResource])
			case "extension":
				guard let val = newValue where val is [FHIRJSON] else {
					_lastSubscriptSetterError = FHIRJSONError(key: "extension", wants: [FHIRJSON].self, has: newValue.dynamicType)
					self.extension_fhir = nil
					return
				}
				self.extension_fhir = Extension.from((val as! [FHIRJSON]), owner: self) as? [Extension]
			case "modifierExtension":
				guard let val = newValue where val is [FHIRJSON] else {
					_lastSubscriptSetterError = FHIRJSONError(key: "modifierExtension", wants: [FHIRJSON].self, has: newValue.dynamicType)
					self.modifierExtension = nil
					return
				}
				self.modifierExtension = Extension.from((val as! [FHIRJSON]), owner: self) as? [Extension]
			default:
				break
			}
		}
	}
	
	/**
	Definition of all properties the receiver defines, including those defined by superclasses.
	*/
	public func elementProperties() -> [FHIRElementPropertyDefn] {
		return [
			FHIRElementPropertyDefn(name: "id", jsonName: "id", type: String.self, isArray: false, mandatory: false, oneOfMany: nil),
			FHIRElementPropertyDefn(name: "contained", jsonName: "contained", type: FHIRContainedResource.self, isArray: true, mandatory: false, oneOfMany: nil),
			FHIRElementPropertyDefn(name: "extension", jsonName: "extension", type: Extension.self, isArray: true, mandatory: false, oneOfMany: nil),
			FHIRElementPropertyDefn(name: "modifierExtension", jsonName: "modifierExtension", type: Extension.self, isArray: true, mandatory: false, oneOfMany: nil),
		]
	}
	
	/**
	Return a property definition for the property in question, if the receiver has such a property.
	
	- parameter property: Property name of the property to get the definition for; this is the "true" FHIR name, as it will appear in JSON
	- returns: A `FHIRElementPropertyDefn` of the respective property, nil if the receiver nor its superclasses define this property
	*/
	public final func definitionOfProperty(property: String) -> FHIRElementPropertyDefn? {
		for prop in elementProperties() {
			if property == prop.jsonName {
				return prop
			}
		}
		return nil
	}
	
	
	// MARK: - JSON Capabilities
	
	/**
	Will populate instance variables - overriding existing ones - with values found in the supplied JSON.
	
	- parameter json: The JSON dictionary to pull data from
	- returns: An optional array of errors reporting missing (when nonoptional) and superfluous properties and
	properties of the wrong type
	*/
	public final func populateFromJSON(json: FHIRJSON?) -> [FHIRJSONError]? {
		if let js = json {
			var present = Set<String>()
			var errors = [FHIRJSONError]()
			
			// loop all properties and assign
			for prop in elementProperties() {
				if "contained" == prop.jsonName {		// handle manually in a sec
					continue
				}
				if let exist = js[prop.jsonName] as? FHIRJSONConvertible {
					present.insert(prop.jsonName)
					_lastSubscriptSetterError = nil
					self[prop.jsonName] = exist
					if let err = _lastSubscriptSetterError {
						errors.append(err)
					}
				}
				else if prop.mandatory {
					errors.append(FHIRJSONError(key: prop.jsonName))
				}
			}
			
			// extract contained resources
			if let exist: AnyObject = js["contained"] {
				present.insert("contained")
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
			
			// superfluous JSON entries?
			_ = js.keys.filter() { !present.contains($0) }.map() { errors.append(FHIRJSONError(key: $0, has: js[$0]!.dynamicType)) }
//			if let supflu = superfluous where !supflu.isEmpty {
//				for sup in supflu {
//					errors.append(FHIRJSONError(key: sup, has: json![sup]!.dynamicType))
//				}
//			}
			return errors.isEmpty ? nil : errors
		}
		return nil
	}
	
	/**
		Represent the receiver in FHIRJSON, ready to be used for JSON serialization.
	 */
	public func asJSON() -> FHIRJSONConvertible {
		var json = FHIRJSON()
		//json["resourceType"] = self.dynamicType.resourceName		// we only do this for resources
		
		for prop in elementProperties() {
			if let exist = self[prop.jsonName] {
				json[prop.jsonName] = (exist.asJSON() as! AnyObject)
			}
		}
		return json
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
	
	- parameter containedResource: The instance to add to the `contained` dictionary
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
	
	- parameter resource: The resource to contain
	- parameter withId: The id to use as internal reference
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

