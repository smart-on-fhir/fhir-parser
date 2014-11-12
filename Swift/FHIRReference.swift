//
//  FHIRReference.swift
//  SMART-on-FHIR
//
//  Created by Pascal Pfiffner on 10/14/14.
//  2014, SMART Platforms.
//

import Foundation


/**
 *  A subclass to ResourceReference. This allows reference resolving while keeping the the superclass'es attributes
 *  in place.
 */
public class FHIRReference<T: FHIRElement>: ResourceReference
{
	public required init(json: NSDictionary?) {
		super.init(json: json)
	}
	
	// Must override to prevent the Swift compiler from segfaulting (segfault 11). Huh.
	public convenience init(json: NSDictionary?, owner: FHIRElement?) {
		self.init(json: json)
		_owner = owner
	}
	
	class func from(array: [NSDictionary], owner: FHIRElement) -> [FHIRReference<T>] {
		var arr: [FHIRReference<T>] = []
		for arrJSON in array {
			arr.append(FHIRReference<T>(json: arrJSON, owner: owner))
		}
		return arr
	}
	
	
	// MARK: - Reference Resolving
	
	/** Resolves the reference and returns an Optional for the instance of the referenced type. */
	public func resolved() -> T? {
		let refid = processedReferenceIdentifier()
		if nil == refid {
			println("This reference does not have a reference-id, cannot resolve")
			return nil
		}
		
		if let resolved = resolvedReference(refid!) {
			return (resolved as T)
		}
		
		// not yet resolved, let's look at contained resources
		if let contained = containedReference(refid!) {
			let t = T.self									// getting crashes when using T(...) directly as of 6.1 GM 2
			let instance = t(json: contained.json)
			didResolveReference(refid!, resolved: instance)
			return instance
		}
		
		// TODO: Fetch remote resources
		println("TODO: must resolve referenced resource \"\(refid!)\" for \(_owner)")
		
		return nil
	}
	
	func processedReferenceIdentifier() -> String? {
		if nil == reference {
			return nil
		}
		
		// fragment only: we are looking for a contained resource
		if "#" == reference![reference!.startIndex] {
			return reference![advance(reference!.startIndex, 1)..<reference!.endIndex]
		}
		
		// TODO: treat as absolute URL if we find a scheme separator "://"
		
		return reference
	}
}

