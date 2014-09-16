//
//  FHIRElement.swift
//  SMART-on-FHIR
//
//  Created by Pascal Pfiffner on 7/2/14.
//  Copyright (c) 2014 SMART Platforms. All rights reserved.
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
	
	/** This should be `extension` but it is a keyword in Swift; renamed to `fhirExtension`. */
	public var fhirExtension: [Extension]?
	
	/** Optional modifier extensions. */
	public var modifierExtension: [Extension]?
	
	/** Contained, inline Resources, indexed by key. */
	public var contained: [String: FHIRContainedResource]?
	
	/** Mapping ResourceReference instances to property names (singles).
	 *  This is needed due to lack of introspection as of beta 3. */
	var _referenceMap = [String: ResourceReference]()

	/** Mapping ResourceReference instances to property names (multiples). */
	var _referencesMap = [String: [ResourceReference]]()
	
	/** Resolved references (singles). */
	var _resolved: [String: FHIRElement]?
	
	/** Resolved references (multiples). */
	var _resolveds: [String: [FHIRElement]]?
	
	
	// MARK: - JSON Capabilities
	
	required public init(json: NSDictionary?) {
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
		}
	}
	
	final class func from(array: [NSDictionary]) -> [FHIRElement] {
		var arr: [FHIRElement] = []
		for arrJSON in array {
			arr.append(self(json: arrJSON))
		}
		return arr
	}
	
	
	// MARK: - Handling References
	
	func didSetReference(object: FHIRElement, name: String) {
		if let obj = object as? ResourceReference {
			_referenceMap[name] = obj
		}
	}
	
	func didSetReferences(object: [FHIRElement], name: String) {
		if let obj = object as? [ResourceReference] {
			_referencesMap[name] = obj
		}
	}
	
	func resolveReference(name: String) -> FHIRElement? {
		if let resolved = _resolved?[name] {
			return resolved
		}
		
		// not yet resolved: get the ResourceReference instance for the property name from `_referenceMap`, find the
		// FHIRContainedResource with the correct id in `contained`, instantiate from cached json and cached the
		// instance in `_referenceMap`.
		if let reference = _referenceMap[name] as ResourceReference? {
			if let refid = FHIRContainedResource.processIdentifier(reference.reference) {
				if let cont = contained?[refid] {
					if let resolved = cont.resolve() {
						var res = _resolved ?? [String: FHIRElement]()
						res[name] = resolved
						_resolved = res
						
						// TODO: could now throw contained[refid] away to free up RAM
						
						return resolved
					}
				}
				else {
					println("Should resolve \(name) but do NOT have contained item with id \"\(reference.reference)\" in \(contained)")
				}
			}
			else {
				println("Should resolve \(name) but do NOT have reference for id \"\(reference.reference)\"")
			}
		}
		
		return nil
	}
	
	func resolveReferences(name: String) -> [FHIRElement]? {
		if let resolved = _resolveds?[name] {
			return resolved
		}
		
		// TODO: implement!
		fatalError("Must implement resource references that reference arrays")
		return nil
	}
}

