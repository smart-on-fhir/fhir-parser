//
//  FHIRSearch.swift
//  SMART-on-FHIR
//
//  Created by Pascal Pfiffner on 7/10/14.
//  2014, SMART Platforms.
//

import Foundation

let FHIRSearchErrorDomain = "FHIRSearchErrorDomain"


/**
	Instances of this class can perform searches on a server.

	Searches are instantiated from MongoDB-like query constructs, like:

	    let srch = Patient.search(["address": "Boston", "gender": "male", "given": ["$exact": "Willis"]])

	Then srch.perform() will run the following URL query against the server:

	    "Patient?address=Boston&gender=male&given:exact=Willis"
 */
public class FHIRSearch
{
	/// The first search parameter must define a profile type to which the search is applied.
	public var profileType: FHIRResource.Type?
	
	/// The query construct used to describe the search
	let query: FHIRSearchConstruct
	
	/// The sorting to request. Use tuples with the value followed by "asc" or "desc": [("given", "asc"), ("family", "asc")].
	public var sort: [(String, String)]?
	
	/// The number of results to return per page; leave nil to let the server decide.
	public var pageCount: Int?
	
	/// The URL to retrieve the next page of results from; nil if there are no more results.
	var nextPageURL: NSURL?
	
	var busy = false
	
	/// Returns true if there are more search results to be fetched.
	public var hasMore: Bool {
		return (nil != nextPageURL)
	}
	
	
	/** Designated initializer. */
	public init(query: AnyObject) {
		self.query = FHIRSearchConstruct(construct: query)
	}
	
	/** Convenience initializer. */
	public convenience init(type: FHIRResource.Type, query: AnyObject) {
		self.init(query: query)
		profileType = type
	}
	
	
	// MARK: - Running Search
	
	func reset() {
		nextPageURL = nil
	}
	
	/**
		Creates the relative server path and query URL string.
	 */
	public func construct() -> String {
		var extra = [FHIRURLParam]()
		if let count = pageCount {
			extra.append(FHIRURLParam(name: "_count", value: "\(count)"))
		}
		if let sorters = sort {
			for (val, ord) in sorters {
				extra.append(FHIRURLParam(name: "_sort:\(ord)", value: val))
			}
		}
		
		// expand
		let qry = query.expand(extraArguments: extra)
		if let type = profileType {
			if countElements(qry) > 0 {
				return "\(type.resourceName)?\(qry)"
			}
			return type.resourceName
		}
		if countElements(qry) > 0 {
			return "?\(qry)"
		}
		return ""
	}
	
	/**
		Performs a GET on the server after constructing the query URL, returning an error or a bundle resource with the
		callback.
	
		Calling this method will always restart search, not fetch subsequent pages.
	
		:param: server The FHIRServer instance on which to perform the search
		:param: callback The callback, receives the response Bundle or an NSError message describing what went wrong
	 */
	public func perform(server: FHIRServer, callback: ((bundle: Bundle?, error: NSError?) -> Void)) {
		if nil == profileType {
			let err = NSError(domain: FHIRSearchErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Cannot find the profile type against which to run the search"])
			callback(bundle: nil, error: err)
			return
		}
		
		reset()
		performSearch(server, queryPath: construct(), callback: callback)
	}
	
	/**
		Attempts to retrieve the next page of search results. If there are none, the callback is called immediately
		with no bundle and no error.
	
		:param: server The FHIRServer instance on which to perform the search
		:param: callback The callback, receives the response Bundle or an NSError message describing what went wrong
	 */
	public func nextPage(server: FHIRServer, callback: ((bundle: Bundle?, error: NSError?) -> Void)) {
		if let next = nextPageURL?.absoluteString {
			performSearch(server, queryPath: next, callback: callback)
		}
		else {
			callback(bundle: nil, error: nil)
		}
	}
	
	func performSearch(server: FHIRServer, queryPath: String, callback: ((bundle: Bundle?, error: NSError?) -> Void)) {
		if busy {
			callback(bundle: nil, error: nil)
			return
		}
		
		busy = true
		server.getJSON(queryPath) { response in
			self.busy = false
			
			if let error = response.error {
				callback(bundle: nil, error: error)
			}
			else {
				let bundle = Bundle(json: response.json)
				bundle._server = server
				if let entries = bundle.entry {
					for entry in entries {
						entry.resource?._server = server		// workaround for when "Bundle" gets deallocated
					}
				}
				
				// is there more?
				self.nextPageURL = nil
				if let links = bundle.link {
					for link in links {
						if "next" == link.relation {
							self.nextPageURL = link.url
							break
						}
					}
				}
				
				callback(bundle: bundle, error: nil)
			}
		}
	}
}


/**
	Instances of this struct represent URL query parameters.
 */
struct FHIRURLParam
{
	/// Parameter name
	let name: String
	
	/// Parameter value
	let value: String
	
	
	func asParameter() -> String {
		return "\(name)=\(value)"		// TODO: encode value
	}
}


/**
	This class is used to create FHIRURLParam instances from FHIRSearchConstruct objects.
 */
class FHIRSearchParam: Printable
{
	var name: String?
	var isModifier = false
	var value: String?
	weak var parent: FHIRSearchParam?
	var children: [FHIRSearchParam]? {
		didSet {
			if let chldrn = children {
				for child in chldrn {
					child.parent = self
				}
			}
		}
	}
	var description: String {
		return "<FHIRSearchParam> \(name ?? nil) [parent \(parent?.description ?? nil) and \(nil != children ? countElements(children!) : 0) children]"
	}
	
	init(name: String, parent: FHIRSearchParam?) {
		self.name = name
		self.parent = parent
	}
	
	init(value: String, parent: FHIRSearchParam?) {
		self.value = value
		self.parent = parent
	}
	
	/** Instantiate from any object, delegating to FHIRSearchConstruct to figure out what the object means. */
	class func from(any: AnyObject, parent: FHIRSearchParam?) -> [FHIRSearchParam] {
		if let str = any as? String {
			return [FHIRSearchParam(value: str, parent: parent)]
		}
		if let bol = any as? Bool {
			return [FHIRSearchParam(value: bol ? "true" : "false", parent: parent)]
		}
		
		let construct = FHIRSearchConstruct(construct: any)
		return construct.prepare(parent)
	}
	
	/** Recursively determine the parameter name, looking at all parent objects. */
	func parentName() -> String? {
		var full = name
		if let prnt = parent?.parentName() {
			if nil != full {
				if isModifier {
					full = "\(prnt)\(full!)"
				}
				else {
					full = "\(prnt).\(full!)"
				}
			}
			else {
				full = prnt
			}
		}
		return full
	}
	
	/** Expand all children to instantiate FHIRURLParam objects. */
	func expand() -> [FHIRURLParam] {
		if let chldren = children {
			var arr = [FHIRURLParam]()
			for child in chldren {
				arr.extend(child.expand())
			}
			return arr
		}
		else if let val = value {
			return [FHIRURLParam(name: parentName() ?? "", value: val)]
		}
		return []
	}
}


struct FHIRSearchConstruct
{
	static var handlers: [FHIRSearchConstructHandler] = [
		FHIRSearchConstructAndHandler(),
		FHIRSearchConstructOrHandler(),
		FHIRSearchConstructModifierHandler(),
		FHIRSearchConstructOperatorHandler(),
		FHIRSearchConstructTypeHandler(),
	]
	
	static func handlerFor(key: String) -> FHIRSearchConstructHandler? {
		for handler in self.handlers {
			if handler.handles(key) {
				return handler
			}
		}
		return nil
	}
	
	
	let construct: AnyObject
	
	init(construct: AnyObject) {
		self.construct = construct
	}
	
	func expand(extraArguments: [FHIRURLParam]? = nil) -> String {
		var arr = [String]()
		for params in self.prepare(nil) {
			for param in params.expand() {
				arr.append(param.asParameter())
			}
		}
		if let extras = extraArguments {
			for extra in extras {
				arr.append(extra.asParameter())
			}
		}
		
		return "&".join(arr)
	}
	
	func prepare(parent: FHIRSearchParam?) -> [FHIRSearchParam] {
		var arr = [FHIRSearchParam]()
		if let myarr = construct as? [AnyObject] {
			for any in myarr {
				let sub = FHIRSearchConstruct(construct: any)
				arr.extend(sub.prepare(nil))
			}
			return arr
		}
		
		if let dict = construct as? [String: AnyObject] {
			for (key, val) in dict {
				//println("-> \(key): \(val)")
				var param = FHIRSearchParam(name: key, parent: parent)
				
				// special handling?
				if let handler = self.dynamicType.handlerFor(key) {
					handler.handle(param, value: val)
				}
					
				// this is a sub-structure, expand
				else if let dict = val as? [String: AnyObject] {
					let construct = FHIRSearchConstruct(construct: dict)
					param.children = construct.prepare(param)
				}
					
				// a string
				else if let str = val as? String {
					param.value = str
				}
				else {
					println("WARNING: no idea what to do with \(key): \(val), ignoring")
				}
				arr.append(param)
			}
			return arr
		}
		
		println("WARNING: not sure what to do with \"\(construct)\"")
		return arr
	}
}


// MARK: - Special Handlers

protocol FHIRSearchConstructHandler
{
	func handles(key: String) -> Bool
	func handle(param: FHIRSearchParam, value: AnyObject)
}


struct FHIRSearchConstructAndHandler: FHIRSearchConstructHandler
{
	func handles(key: String) -> Bool {
		return ("$and" == key)
	}
	
	func handle(param: FHIRSearchParam, value: AnyObject) {
		if let arr = value as? [AnyObject] {
			param.name = nil
			var ret = [FHIRSearchParam]()
			for obj in arr {
				ret.extend(FHIRSearchParam.from(obj, parent: param.parent))
			}
			
			if nil != param.children {
				param.children!.extend(ret)
			}
			else {
				param.children = ret
			}
		}
		else {
			println("ERROR: must supply an array of objects to an $and modifier")
		}
	}
}


struct FHIRSearchConstructOrHandler: FHIRSearchConstructHandler
{
	func handles(key: String) -> Bool {
		return ("$or" == key)
	}
	
	func handle(param: FHIRSearchParam, value: AnyObject) {
		if let arr = value as? [AnyObject] {
			var strs = [String]()
			for obj in arr {
				if let str = obj as? String {
					strs.append(str)
				}
				else {
					println("WARNING: what do I do with \(obj)?")
				}
			}
			param.name = nil
			param.value = ",".join(strs)
		}
		else {
			println("ERROR: must supply an array of objects to an $or modifier")
		}
	}
}


struct FHIRSearchConstructModifierHandler: FHIRSearchConstructHandler
{
	static let map = [
//		"$asc": ":asc",
//		"$desc": ":desc",
		"$exact": ":exact",
		"$missing": ":missing",
		"$null": ":missing",
		"$text": ":text",
	]
	
	func handles(key: String) -> Bool {
		return contains(FHIRSearchConstructModifierHandler.map.keys, key)
	}
	
	func handle(param: FHIRSearchParam, value: AnyObject) {
		if let modifier = FHIRSearchConstructModifierHandler.map[param.name ?? ""] {
			param.name = modifier
			param.isModifier = true
			param.children = FHIRSearchParam.from(value, parent: param)
		}
		else {
			println("ERROR: unknown modifier \(param.name)")
		}
	}
}


struct FHIRSearchConstructOperatorHandler: FHIRSearchConstructHandler
{
	static let map = [
		"$gt": "%3E",           // NSURL() fails if un-encoded ">" and "<" are present in the query part
		"$lt": "%3C",
		"$lte": "%3C%3D",       // NSURL() does not fail on "=" but let's also encode these to be consistent
		"$gte": "%3E%3D",
	]
	
	func handles(key: String) -> Bool {
		return contains(FHIRSearchConstructOperatorHandler.map.keys, key)
	}
	
	func handle(param: FHIRSearchParam, value: AnyObject) {
		if let modifier = FHIRSearchConstructOperatorHandler.map[param.name!] {
			if let str = value as? String {
				param.name = nil
				param.value = "\(modifier)\(str)"
			}
		}
		else {
			println("ERROR: unknown operator \(param.name) for \(value)")
		}
	}
}


struct FHIRSearchConstructTypeHandler: FHIRSearchConstructHandler
{
	func handles(key: String) -> Bool {
		return ("$type" == key)
	}
	
	func handle(param: FHIRSearchParam, value: AnyObject) {
		if let type = value as? String {
			if let parent = param.parent {
				parent.name = (parent.name ?? "") + ":\(type)"
			}
			else {
				println("ERROR: must have a parent parameter to use $type")
			}
		}
		else {
			println("ERROR: must supply a String to a $type modifier, got \(value)")
		}
	}
}

