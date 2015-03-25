//
//  FHIRModelTestCase.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 8/27/14.
//  2014, SMART Platforms.
//

import XCTest
import SwiftFHIR


/**
 *  Superclass for FHIR model tests providing a `readJSONFile(filename:)` method to read JSON files from disk.
 */
class FHIRModelTestCase: XCTestCase
{
	class var testsDirectory: String {
		let dir = __FILE__
		let proj = dir.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent
		return proj.stringByAppendingPathComponent("fhir-parser/downloads")
	}
	
	func readJSONFile(filename: String) -> FHIRJSON? {
		let dir = self.dynamicType.testsDirectory
		XCTAssertTrue(NSFileManager.defaultManager().fileExistsAtPath(dir), "You must either first download the FHIR spec or manually adjust `FHIRModelTestCase.testsDirectory` to point to your FHIR download directory")
		
		let path = dir.stringByAppendingPathComponent(filename)
		let data = NSData(contentsOfFile: path)
		XCTAssertNotNil(data, "Unable to read \"\(path)")
		if nil == data { return nil }
		
		let json = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil) as? FHIRJSON
		XCTAssertNotNil(json, "Unable to decode \"\(path)")
		
		return json
	}
}

