//
//  FHIRElement.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 7/2/14.
//  2014, SMART Platforms.
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
	var _resolved: [String: FHIRElement]?
	
	/// Additional Content defined by implementations
	public var extension_fhir: [Extension]?
	
	/// Extensions that cannot be ignored
	public var modifierExtension: [Extension]?
	
	
	// MARK: - JSON Capabilities
	
	public required init(json: FHIRJSON?) {
		if let js = json {
			if let val = js["id"] as? String {
				self.id = val
			}
			if let arr = js["contained"] as? [FHIRJSON] {
				var cont = contained ?? [String: FHIRContainedResource]()
				for dict in arr {
					let res = FHIRContainedResource(json: dict, owner: self)
					if nil != res.id {
						cont[res.id!] = res
					}
					else {
						println("Contained resource in \(self) without \"_id\" will be ignored")
					}
				}
				contained = cont
			}
			if let val = js["extension"] as? [FHIRJSON] {
				self.extension_fhir = Extension.from(val, owner: self) as? [Extension]
			}
			if let val = js["modifierExtension"] as? [FHIRJSON] {
				self.modifierExtension = Extension.from(val, owner: self) as? [Extension]
			}
		}
	}
	
	/**
		Represent the receiver in a FHIRJSON, ready to be used for JSON serialization.
	 */
	public func asJSON() -> FHIRJSON {
		var json = FHIRJSON()
		//json["resourceType"] = self.dynamicType.resourceName		// we only do this for resources
		
		if let id = self.id {
			json["id"] = id.asJSON()
		}
		if let contained = self.contained {
			var arr = [FHIRJSON]()
			for (key, val) in contained {
				arr.append(val.json ?? FHIRJSON())		// TODO: check if it has been resolved, if so use `asJSON()`
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
		Calls `asJSON()` on all elements in the array and returns the resulting array full of JSONDictionaries.
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
	final class func instantiateFrom(json: FHIRJSON?, owner: FHIRElement?) -> FHIRElement {
		if let type = json?["resourceType"] as? String {
			return factory(type, json: json!, owner: owner)
		}
		let instance = self(json: json)		// must use 'required' init with dynamic type
		instance._owner = owner
		return instance
	}
	
	/**
		Instantiates an array of the receiver's type and returns it.
		TODO: Returning [Self] is not yet possible (Xcode 6.2b3), too bad
	 */
	final class func from(array: [FHIRJSON]) -> [FHIRElement] {
		var arr: [FHIRElement] = []
		for arrJSON in array {
			arr.append(self(json: arrJSON))
		}
		return arr
	}
	
	/**
		Instantiates an array of the receiver's type and returns it.
	 */
	final class func from(array: [FHIRJSON], owner: FHIRElement?) -> [FHIRElement] {
		let arr = from(array)
		for elem in arr {
			elem._owner = owner			// would be neater to use init(json:owner:) but cannot use non-required init with dynamic type
		}
		return arr
	}
	
	
	// MARK: - Handling References
	
	/** Returns the contained reference with the given id, if it exists. */
	func containedReference(refid: String) -> FHIRContainedResource? {
		if let cont = contained?[refid] {
			return cont
		}
		return _owner?.containedReference(refid)
	}
	
	/** Returns the resolved reference with the given id, if it has been resolved already. */
	func resolvedReference(refid: String) -> FHIRElement? {
		if let resolved = _resolved?[refid] {
			return resolved
		}
		return _owner?.resolvedReference(refid)
	}
	
	/**
		Stores the resolved reference into the `_resolved` dictionary.
	
		Called by FHIRResource when it resolves a reference.
	
		:param: refid The reference identifier as String
		:param: resolved The element that was resolved
	 */
	func didResolveReference(refid: String, resolved: FHIRElement) {
		if nil != _resolved {
			_resolved![refid] = resolved
		}
		else {
			_resolved = [refid: resolved]
		}
	}
	
	
	// MARK: - Printable
	
	public var description: String {
		return "<\(self.dynamicType.resourceName)>"
	}
}

