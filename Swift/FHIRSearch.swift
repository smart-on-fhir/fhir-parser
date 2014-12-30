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
	let construct: FHIRSearchConstruct
	
	/** Designated initializer. */
	init(query: AnyObject) {
		self.construct = FHIRSearchConstruct(construct: query)
	}
	
	/** Convenience initializer. */
	convenience init(type: FHIRResource.Type, query: AnyObject) {
		self.init(query: query)
		profileType = type
	}
	
	
	// MARK: - Running Search
	
	/**
		Usually called on the **last** search param in a chain; creates the search URL from itself and its preceding
		siblings, then performs a GET on the server, returning an error or an array of resources in the callback.
	
		:param: server The FHIRServer instance on which to perform the search
		:param: callback The callback, receives the response Bundle or an NSError message describing what went wrong
	 */
	public func perform(server: FHIRServer, callback: ((bundle: Bundle?, error: NSError?) -> Void)) {
		if nil == profileType {
			let err = NSError(domain: FHIRSearchErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Cannot find the profile type against which to run the search"])
			callback(bundle: nil, error: err)
			return
		}
		
		let path = "\(profileType!.resourceName)?\(construct.expand())"
		server.requestJSON(path) { json, error in
			if nil != error {
				callback(bundle: nil, error: error)
			}
			else {
				callback(bundle: Bundle(json: json), error: nil)
			}
		}
	}
}


/**
	Instances of this struct represent URL query parameters.
 */
struct FHIRSearchParam
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
	This class is used to create FHIRSearchParam instances from FHIRSearchConstruct objects.
 */
class FHIRSearchParamProto: Printable
{
	var name: String?
	var isModifier = false
	var value: String?
	weak var parent: FHIRSearchParamProto?
	var children: [FHIRSearchParamProto]? {
		didSet {
			if let chldrn = children {
				for child in chldrn {
					child.parent = self
				}
			}
		}
	}
	var description: String {
		return "<FHIRSearchParamProto> \(name ?? nil) [parent \(parent?.description ?? nil) and \(nil != children ? countElements(children!) : 0) children]"
	}
	
	init(name: String, parent: FHIRSearchParamProto?) {
		self.name = name
		self.parent = parent
	}
	
	init(value: String, parent: FHIRSearchParamProto?) {
		self.value = value
		self.parent = parent
	}
	
	/** Instantiate from any object, delegating to FHIRSearchConstruct to figure out what the object means. */
	class func from(any: AnyObject, parent: FHIRSearchParamProto?) -> [FHIRSearchParamProto] {
		if let str = any as? String {
			return [FHIRSearchParamProto(value: str, parent: parent)]
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
	
	/** Resolve all children to instantiate FHIRSearchParam objects. */
	func apply() -> [FHIRSearchParam] {
		if let chldren = children {
			var arr = [FHIRSearchParam]()
			for child in chldren {
				arr.extend(child.apply())
			}
			return arr
		}
		else if let val = value {
			return [FHIRSearchParam(name: parentName() ?? "", value: val)]
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
	
	func expand() -> String {
		var arr = [String]()
		for params in self.prepare(nil) {
			for param in params.apply() {
				arr.append(param.asParameter())
			}
		}
		
		return "&".join(arr)
	}
	
	func prepare(parent: FHIRSearchParamProto?) -> [FHIRSearchParamProto] {
		var arr = [FHIRSearchParamProto]()
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
				var param = FHIRSearchParamProto(name: key, parent: parent)
				
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
		
		println("WARNING: not sure what to do with \(construct)")
		return arr
	}
}


// MARK: - Special Handlers

protocol FHIRSearchConstructHandler
{
	func handles(key: String) -> Bool
	func handle(param: FHIRSearchParamProto, value: AnyObject)
}


struct FHIRSearchConstructAndHandler: FHIRSearchConstructHandler
{
	func handles(key: String) -> Bool {
		return ("$and" == key)
	}
	
	func handle(param: FHIRSearchParamProto, value: AnyObject) {
		if let arr = value as? [AnyObject] {
			param.name = nil
			var ret = [FHIRSearchParamProto]()
			for obj in arr {
				ret.extend(FHIRSearchParamProto.from(obj, parent: param.parent))
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
	
	func handle(param: FHIRSearchParamProto, value: AnyObject) {
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
	
	func handle(param: FHIRSearchParamProto, value: AnyObject) {
		if let modifier = FHIRSearchConstructModifierHandler.map[param.name!] {
			param.name = modifier
			param.isModifier = true
			param.children = FHIRSearchParamProto.from(value, parent: param)
		}
		else {
			println("ERROR: unknown modifier \(param.name)")
		}
	}
}


struct FHIRSearchConstructOperatorHandler: FHIRSearchConstructHandler
{
	static let map = [
		"$gt": ">",
		"$lt": "<",
		"$lte": "<=",
		"$gte": ">=",
	]
	
	func handles(key: String) -> Bool {
		return contains(FHIRSearchConstructOperatorHandler.map.keys, key)
	}
	
	func handle(param: FHIRSearchParamProto, value: AnyObject) {
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
	
	func handle(param: FHIRSearchParamProto, value: AnyObject) {
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

