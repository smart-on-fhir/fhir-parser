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
	
	/// Resolved references.
	var _resolved: [String: FHIRElement]?
	
	
	// MARK: - JSON Capabilities
	
	public init() {
	}
	
	public required init?(json: NSDictionary) {
		if let arr = json["contained"] as? [NSDictionary] {
			var cont = contained ?? [String: FHIRContainedResource]()
			for dict in arr {
				if let res = FHIRContainedResource(json: dict) {
					cont[res.id] = res
				}
				else {
					println("Failed to initialize contained resource in \(self), possibly missing \"id\"?")
				}
			}
			contained = cont
		}
	}
	
	public final class func from(array: [NSDictionary]) -> [FHIRElement]? {
		var arr: [FHIRElement] = []
		for dict in array {
			if let instance = self(json: dict) {
				arr.append(instance)
			}
		}
		return arr.count > 0 ? arr : nil
	}
	
	
	// MARK: - Handling References
	
	/** Returns the contained reference with the given id, if it exists. */
	func containedReference(refid: String) -> FHIRContainedResource? {
		return contained?[refid]
	}
	
	/** Returns the resolved reference with the given id, if it has been resolved already. */
	func resolvedReference(refid: String) -> FHIRElement? {
		return _resolved?[refid]
	}
	
	/** Called by FHIRResource when it resolves a reference. Stores the resolved reference into the `_resolved`
	 *  dictionary.
	 */
	func didResolveReference(refid: String, resolved: FHIRElement) {
		if nil != _resolved {
			_resolved![refid] = resolved
		}
		else {
			_resolved = [refid: resolved]
		}
	}
}

