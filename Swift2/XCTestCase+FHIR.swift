//
//  XCTestCase+FHIR.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 8/27/14.
//  2014, SMART Health IT.
//

import XCTest
import SwiftFHIR


/**
 *  Extension providing a `readJSONFile(filename:)` method to read JSON files from disk.
 */
extension XCTestCase {
	
	class var testsDirectory: String {
		let dir = #file as NSString
		let proj = ((dir.stringByDeletingLastPathComponent as NSString).stringByDeletingLastPathComponent as NSString).stringByDeletingLastPathComponent as NSString
		return proj.stringByAppendingPathComponent("fhir-parser/downloads")
	}
	
	func readJSONFile(filename: String) throws -> FHIRJSON {
		let dir = self.dynamicType.testsDirectory
		XCTAssertTrue(NSFileManager.defaultManager().fileExistsAtPath(dir), "You must either first download the FHIR spec or manually adjust `XCTestCase.testsDirectory` to point to your FHIR download directory")
		
		let path = (dir as NSString).stringByAppendingPathComponent(filename)
		let data = NSData(contentsOfFile: path)
		if nil == data {
			throw FHIRError.Error("Unable to read «\(path)»")
		}
		
		let json = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? FHIRJSON
		if let json = json {
			return json
		}
		throw FHIRError.Error("Unable to decode «\(path)» to JSON")
	}
}

