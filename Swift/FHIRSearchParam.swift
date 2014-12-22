//
//  FHIRSearchParam.swift
//  SMART-on-FHIR
//
//  Created by Pascal Pfiffner on 7/10/14.
//  2014, SMART Platforms.
//

import Foundation

let FHIRSearchErrorDomain = "FHIRSearchErrorDomain"


/**
 *  Instances of this class are used to construct parameters for a FHIR search.
 *  
 *  Search parameters are designed to be chained together. The first parameter instance in the chain must define
 *  `profileType`, all subsequent params must have their `subject` set to be useful. Upon calling `construct()` on
 *  the last item in a chain, all instances are constructed into a URL path with arguments, like:
 *  
 *      let qry = Patient.search().address("Boston").gender("male").given_exact("Willis")
 *  
 *  Then qry.construct() will create the string:
 *  
 *      "Patient?address=Boston&gender=male&given:exact=Willis"
 */
public class FHIRSearchParam
{
	/** The name of the search parameter. */
	public var subject: String?
	
	/** The first search parameter must define a profile type to which the search is applied. */
	public var profileType: FHIRResource.Type?
	
	/** The preceding search param instance in a chain. */
	public var previous: FHIRSearchParam? {							// `public` to enable unit testing
		didSet(oldPrev) {
			if nil != previous && self !== previous!.next {
				previous!.next = self
			}
			if oldPrev !== previous && self === oldPrev?.next {
				oldPrev!.next = nil
			}
		}
	}
	
	/** The next search param in a chain. */
	public weak var next: FHIRSearchParam? {						// `public` to enable unit testing
		didSet(oldNext) {
			if nil != next && self !== next!.previous {
				next!.previous = self
			}
			if oldNext !== next && self === oldNext?.previous {
				oldNext!.previous = nil
			}
		}
	}
	
	/** On which profiles the receiver's subject is supported; can be used for validation. */
	public var supportedProfiles: [String]?
	
	
	/** The param's value is a string.
	 *  http://www.hl7.org/implement/standards/fhir/search.html#string
	 */
	public var string: String?
	
	/** The param's value is a token. Can be modified with `tokenAsText`.
	 *  http://www.hl7.org/implement/standards/fhir/search.html#token
	 */
	public var token: String?
	
	/** The param describes a numerical value.
	 *  http://www.hl7.org/implement/standards/fhir/search.html#number
	 */
	public var number: Float?
	
	/** The param's value is a date string.
	 *  http://www.hl7.org/implement/standards/fhir/search.html#date
	 */
	public var date: String?
	
	/** The param describes a numerical quantity.
	 *  http://www.hl7.org/implement/standards/fhir/search.html#quantity
	 */
	public var quantity: String?
	
	/** The param's value is a reference.
	 *  http://www.hl7.org/implement/standards/fhir/search.html#reference
	 */
	public var reference: String?
	
	/** A composite search parameter.
	 *  http://www.hl7.org/implement/standards/fhir/search.html#combining
	 */
	public var composite: [String: String]?
	
	
	// Modifiers: http://www.hl7.org/implement/standards/fhir/search.html#modifiers
	
	/** If `true` we're looking for a missing parameter. */
	public var missing: Bool?
	
	/** Only needed for strings; if `true` the match must be exact. */
	public var stringExact = false
	
	/** Only needed for tokens; if `true` the token should be queried like text. */
	public var tokenAsText = false
	
	/** Only needed for references: the type of the reference. */
	public var referenceType: String?
	
	
	public init(subject: String?) {
		self.subject = subject
	}
	
	public convenience init(profileType: FHIRResource.Type) {
		self.init(subject: nil)
		self.profileType = profileType
	}
	
	public convenience init(subject: String, missing: Bool) {
		self.init(subject: subject)
		self.missing = missing
	}
	
	
	public convenience init(subject: String, token: String) {
		self.init(subject: subject)
		self.token = token
	}
	
	public convenience init(subject: String, tokenAsText: String) {
		self.init(subject: subject, token: tokenAsText)
		self.tokenAsText = true
	}
	
	
	public convenience init(subject: String, string: String) {
		self.init(subject: subject)
		self.string = string
	}
	
	public convenience init(subject: String, exact: String) {
		self.init(subject: subject, string: exact)
		stringExact = true
	}
	
	
	public convenience init(subject: String, number: Float) {
		self.init(subject: subject)
		self.number = number
	}
	
	
	public convenience init(subject: String, date: String) {
		self.init(subject: subject)
		self.date = date
	}
	
	
	public convenience init(subject: String, quantity: String) {
		self.init(subject: subject)
		self.quantity = quantity
	}
	
	
	public convenience init(subject: String, reference: String) {
		self.init(subject: subject)
		self.reference = reference
	}
	
	public convenience init(subject: String, reference: String, type: FHIRResource.Type) {
		self.init(subject: subject, reference: reference)
		profileType = type
	}
	
	
	public convenience init(subject: String, composite: [String: String]) {
		self.init(subject: subject)
		self.composite = composite
	}
	
	
	// MARK: - Construction
	
	func asParam() -> String {
		if nil != subject {
			if nil != missing {
				return "\(subject!):missing=" + (missing! ? "true" : "false")		// TODO: bug in beta 4, `subject` should implicitly unwrap
			}
			if nil != string && stringExact {
				return "\(subject!):exact=\(paramValue())"
			}
			if nil != token && tokenAsText {
				return "\(subject!):text=\(paramValue())"
			}
			return "\(subject!)=\(paramValue())"
		}
		return ""
	}
	
	func paramValue() -> String {
		if nil != string {
			return string!
		}
		if nil != token {
			return token!
		}
		if nil != number {
			return number!.description
		}
		if nil != date {
			return date!
		}
		if nil != quantity {
			return quantity!
		}
		if nil != reference {
			return reference!
		}
		return ""
	}
	
	/**
	 *  Construct the search param string, if the receiver is part of a chain BACK TO the first search param in a chain.
	 *
	 *  Use the `last` method to get the last param of a chain, then construct the parameter string of the whole chain.
	 */
	public func construct() -> String {
		var path = ""
		if nil != previous {
			if nil != subject {
				let prev = previous!.construct()
				let sep = (nil == previous!.previous) ? "?" : "&"
				path = prev + "\(sep)\(asParam())"
			}
			else {
				fatalError("Need a subject to construct a search URL for the 2nd or later argument")
			}
		}
		else if nil != profileType {
			path = profileType!.resourceName
		}
		else {
			fatalError("The first search parameter needs to have \"profileType\" set")
		}
		
		return path
	}
	
	
	// MARK: - Running Search
	
	/**
		Usually called on the **last** search param in a chain; creates the search URL from itself and its preceding
		siblings, then performs a GET on the server, returning an error or an array of resources in the callback.
	
		:param: server The FHIRServer instance on which to perform the search
		:param: callback The callback, receives the response Bundle or an NSError message describing what went wrong
	 */
	public func perform(server: FHIRServer, callback: ((bundle: Bundle?, error: NSError?) -> Void)) {
		let type = first().profileType
		if nil == type {
			let err = NSError(domain: FHIRSearchErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Cannot find the profile type against which to run the search"])
			callback(bundle: nil, error: err)
			return
		}
		
		server.requestJSON(construct()) { json, error in
			if nil != error {
				callback(bundle: nil, error: error)
			}
			else {
				callback(bundle: Bundle(json: json), error: nil)
			}
		}
	}
	
	
	// MARK: - Chaining
	
	func first() -> FHIRSearchParam {
		if nil != previous {
			return previous!.first()
		}
		return self
	}
	
	public func last() -> FHIRSearchParam {				// `public` to enable unit testing
		if nil != next {
			return next!.last()
		}
		return self
	}
}

