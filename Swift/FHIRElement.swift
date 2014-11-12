//
//  FHIRElement.swift
//  SMART-on-FHIR
//
//  Created by Pascal Pfiffner on 7/2/14.
//  2014, SMART Platforms.
//

import Foundation


/**
 *  Abstract superclass for all FHIR data elements.
 */
public class FHIRElement
{
	public class var resourceName: String {
		get { return "FHIRElement" }
	}
	
	/// This should be `extension` but it is a keyword in Swift; renamed to `fhirExtension`.
	public var fhirExtension: [Extension]?
	
	/// Optional modifier extensions.
	public var modifierExtension: [Extension]?
	
	/// Contained, inline Resources, indexed by resource id.
	public var contained: [String: FHIRContainedResource]?
	
	/// The parent/owner of the receiver, if any. Used to dereference resources.
	weak var _owner: FHIRElement?
	
	/// Resolved references.
	var _resolved: [String: FHIRElement]?
	
	
	// MARK: - JSON Capabilities
	
	public required init(json: NSDictionary?) {
		if let js = json {
			if let arr = js["contained"] as? [NSDictionary] {
				var cont = contained ?? [String: FHIRContainedResource]()
				for dict in arr {
					let res = FHIRContainedResource(json: dict)
					if nil != res.id {
						cont[res.id!] = res
					}
					else {
						println("Contained resource in \(self) without \"_id\" will be ignored")
					}
				}
				contained = cont
			}
			if let arr = js["extension"] as? [NSDictionary] {
				self.fhirExtension = Extension.from(arr) as? [Extension]
			}
			if let arr = js["modifierExtension"] as? [NSDictionary] {
				self.modifierExtension = Extension.from(arr) as? [Extension]
			}
		}
	}
	
	public convenience init(json: NSDictionary?, owner: FHIRElement?) {
		self.init(json: json)
		self._owner = owner
	}
	
	final class func from(array: [NSDictionary]) -> [FHIRElement] {
		var arr: [FHIRElement] = []
		for arrJSON in array {
			arr.append(self(json: arrJSON))
		}
		return arr
	}
	
	final class func from(array: [NSDictionary], owner: FHIRElement?) -> [FHIRElement] {
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
	
	/** Called by FHIRResource when it resolves a reference. Stores the resolved reference into the `_resolved`
	 *  dictionary.
	 */
	func didResolveReference(refid: String, resolved: FHIRElement) {
		if let owner = _owner {
			owner.didResolveReference(refid, resolved: resolved)
		}
		else if nil != _resolved {
			_resolved![refid] = resolved
		}
		else {
			_resolved = [refid: resolved]
		}
	}
}

