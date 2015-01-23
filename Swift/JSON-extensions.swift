//
//  JSON-extensions.swift
//  SMART-on-FHIR
//
//  Created by Pascal Pfiffner on 7/4/14.
//  2014, SMART Platforms.
//

import Foundation


extension String
{
	public func asJSON() -> String {
		return self
	}
}

extension Bool
{
	public func asJSON() -> Bool {
		return self
	}
}

extension Int
{
	public func asJSON() -> Int {
		return self
	}
}

extension NSURL
{
	public convenience init?(json: String) {
		self.init(string: json)
	}
	
	public class func from(json: [String]) -> [NSURL] {
		var arr: [NSURL] = []
		for string in json {
			let url: NSURL? = NSURL(string: string)
			if nil != url {
				arr.append(url!)
			}
		}
		return arr
	}
	
	public func asJSON() -> String {
		return self.description
	}
}

extension NSDecimalNumber
{
	/*
		Takes an NSNumber, usually decoded from JSON, and creates an NSDecimalNumber instance
	
		We're using a string format approach using "%.15g" since NSJSONFormatting returns NSNumber objects instantiated
		with Double() or Int(). In the former case this causes precision issues (e.g. try 8.7). Unfortunately, some
		doubles with 16 and 17 significant digits will be truncated (e.g. a longitude of "4.844614000123024").
	
		TODO: improve to avoid double precision issues
	 */
	public convenience init(json: NSNumber) {
		if let periodIdx = find(json.stringValue, ".") {
			self.init(string: NSString(format: "%.15g", json.doubleValue))
		}
		else {
			self.init(string: "\(json)")
		}
	}
	
	public func asJSON() -> NSDecimalNumber {
		return self
	}
}

extension Base64Binary
{
	public init(string: String) {
		self.init(value: string)
	}
	
	public func asJSON() -> String {
		return self.value ?? ""
	}
}

extension Date
{
	public func asJSON() -> String {
		return self.description
	}
}

extension Time
{
	public func asJSON() -> String {
		return self.description
	}
}

extension DateTime
{
	public func asJSON() -> String {
		return self.description
	}
}

extension Instant
{
	public func asJSON() -> String {
		return self.description
	}
}

