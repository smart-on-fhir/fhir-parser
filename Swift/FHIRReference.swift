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
	/// The owner of the reference, used to dereference resources.
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
		let refid = processedReferenceIdentifier()
		if nil == refid {
			println("This reference does not have a reference-id, cannot resolve")
			return nil
		}
		
		if let resolved = owner.resolvedReference(refid!) {
			return (resolved as T)
		}
		
		// not yet resolved, let's look at contained resources
		if let contained = owner.containedReference(refid!) {
			let t = T.self									// getting crashes when using T(...) directly as of 6.1 GM 2
			let instance = t(json: contained.json)
			owner.didResolveReference(refid!, resolved: instance)
			return instance
		}
		
		// TODO: Fetch remote resources
		println("TODO: must resolve referenced resource \"\(refid!)\" for \(owner)")
		
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

