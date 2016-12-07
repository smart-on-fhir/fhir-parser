//
//  JSON-extensions.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 7/4/14.
//  2014, SMART Health IT.
//

import Foundation


extension Bool {
	public func asJSON(errors: inout [FHIRValidationError]) -> Bool {
		return self
	}
}

extension Int {
	public func asJSON(errors: inout [FHIRValidationError]) -> Int {
		return self
	}
}

extension UInt {
	public func asJSON(errors: inout [FHIRValidationError]) -> UInt {
		return self
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
	public convenience init?(json: NSNumber) {
		if let _ = json.stringValue.characters.index(of: ".") {
			self.init(string: String(format: "%.15g", json.doubleValue))
		}
		else {
			self.init(string: "\(json)")
		}
	}
	
	public func asJSON(errors: inout [FHIRValidationError]) -> NSDecimalNumber {
		return self
	}
}

