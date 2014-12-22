//
//  FHIRReference.swift
//  SMART-on-FHIR
//
//  Created by Pascal Pfiffner on 10/14/14.
//  2014, SMART Platforms.
//

import Foundation


/**
 *  An extension to Reference. This allows reference resolving while keeping the superclass'es attributes in place.
 */
extension Reference
{
	/**
		Resolves the reference and returns an Optional for the instance of the referenced type.
	
		:param: type The resource type that should be dereferenced
	 */
	public func resolved<T: FHIRElement>(type: T.Type) -> T? {
		let refid = processedReferenceIdentifier()
		if nil == refid {
			println("This reference does not have a reference-id, cannot resolve")
			return nil
		}
		
		if let resolved = resolvedReference(refid!) {
			if let res = resolved as? T {
				return res
			}
			NSLog("Reference \(refid) was dereferenced to \(resolved), which is not of the expected type \(T.self)")
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

