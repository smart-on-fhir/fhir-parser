//
//  FHIRModelTestCase.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 8/27/14.
//  2014, SMART Platforms.
//

import Cocoa
import XCTest


/**
 *  Superclass for FHIR model tests providing a `readJSONFile(filename:)` method to read JSON files from disk.
 */
class FHIRModelTestCase: XCTestCase
{
	func readJSONFile(filename: String) -> NSDictionary? {
		let path = NSBundle(forClass: self.dynamicType).pathForResource(filename.stringByDeletingPathExtension, ofType: "json")
		XCTAssertNotNil(path, "Did not find \"\(filename)")
		if nil == path { return nil }
		let data = NSData(contentsOfFile: path!)
		XCTAssertNotNil(data, "Unable to read \"\(path)")
		if nil == data { return nil }
		let json = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil) as? NSDictionary
		XCTAssertNotNil(json, "Unable to decode \"\(path)")
		return json
	}
}

