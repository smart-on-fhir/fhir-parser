//
//  JSON-extensions.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 7/4/14.
//  2014, SMART Health IT.
//

import Foundation


extension String {
	public func asJSON() -> String {
		return self
	}
}

extension Bool {
	public func asJSON() -> Bool {
		return self
	}
}

extension Int {
	public func asJSON() -> Int {
		return self
	}
}

extension UInt {
	public func asJSON() -> UInt {
		return self
	}
}

extension URL {
	
	public init?(json: String) {
		self.init(string: json)
	}
	
	public static func instantiate(fromArray json: [String]) -> [URL] {
		var arr: [URL] = []
		for string in json {
			if let url = URL(string: string) {
				arr.append(url)
			}
		}
		return arr
	}
	
	public func asJSON() -> String {
		return self.description
	}
}

extension NSDecimalNumber {
	/*
		Takes an NSNumber, usually decoded from JSON, and creates an NSDecimalNumber instance
	
		We're using a string format approach using "%.15g" since NSJSONFormatting returns NSNumber objects instantiated
		with Double() or Int(). In the former case this causes precision issues (e.g. try 8.7). Unfortunately, some
		doubles with 16 and 17 significant digits will be truncated (e.g. a longitude of "4.844614000123024").
	
		TODO: improve to avoid double precision issues
	 */
	public convenience init(json: NSNumber) {
		if let _ = json.stringValue.characters.index(of: ".") {
			self.init(string: String(format: "%.15g", json.doubleValue))
		}
		else {
			self.init(string: "\(json)")
		}
	}
	
	public func asJSON() -> NSDecimalNumber {
		return self
	}
}

extension Base64Binary {
	public init(string: String) {
		self.init(value: string)
	}
	
	public func asJSON() -> String {
		return self.value ?? ""
	}
}

extension FHIRDate {
	public static func instantiate(fromArray json: [String]) -> [FHIRDate] {
		var arr: [FHIRDate] = []
		for string in json {
			if let obj = FHIRDate(string: string) {
				arr.append(obj)
			}
		}
		return arr
	}
	
	public func asJSON() -> String {
		return self.description
	}
}

extension FHIRTime {
	public static func instantiate(fromArray json: [String]) -> [FHIRTime] {
		var arr: [FHIRTime] = []
		for string in json {
			if let obj = FHIRTime(string: string) {
				arr.append(obj)
			}
		}
		return arr
	}
	
	public func asJSON() -> String {
		return self.description
	}
}

extension DateTime {
	public static func instantiate(fromArray json: [String]) -> [DateTime] {
		var arr: [DateTime] = []
		for string in json {
			if let obj = DateTime(string: string) {
				arr.append(obj)
			}
		}
		return arr
	}
	
	public func asJSON() -> String {
		return self.description
	}
}

extension Instant {
	public static func instantiate(fromArray json: [String]) -> [Instant] {
		var arr: [Instant] = []
		for string in json {
			if let obj = Instant(string: string) {
				arr.append(obj)
			}
		}
		return arr
	}
	
	public func asJSON() -> String {
		return self.description
	}
}

