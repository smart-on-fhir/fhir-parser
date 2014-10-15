//
//  FHIRReference.swift
//  SMART-on-FHIR
//
//  Created by Pascal Pfiffner on 10/14/14.
//  2014, SMART Platforms.
//

import Foundation


/**
 *  Subclassing ResourceReference in order to enable reference resolving while keeping the reference's attributes
 *  in place.
 */
public class FHIRReference<T: FHIRElement>: ResourceReference
{
	/// The owner of the reference, used to dereference from contained resources.
	unowned let owner: FHIRElement
	
	
	// MARK: - Initialization
	
	public required init(json: NSDictionary?) {
		fatalError("Must use init(json:owner:)")
	}
	
	public init(json: NSDictionary?, owner: FHIRElement) {
		self.owner = owner
		super.init(json: json)
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
		if nil == reference {
			println("This reference does not have a reference-id, cannot resolve")
			return nil
		}
		
		if let resolved = owner.resolvedReference(reference!) {
			return (resolved as T)
		}
		
		// not yet resolved, look at contained resources
		if let contained = owner.containedReference(reference!) {
			let t = T.self									// getting crashes when using T(...) directly as of 6.1 GM 2
			let instance = t(json: contained.json)
			owner.didResolveReference(reference!, resolved: instance)
			return instance
		}
		
		// TODO: Fetch remote resources
		println("TODO: must resolve referenced resource \"\(reference!)\" for \(owner)")
		
		return nil
	}
}

