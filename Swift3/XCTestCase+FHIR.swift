//
//  XCTestCase+FHIR.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 8/27/14.
//  2014, SMART Health IT.
//

import XCTest
#if !NO_MODEL_IMPORT
import Models
#else
import SwiftFHIR
#endif


/**
 *  Extension providing a `readJSONFile(filename:)` method to read JSON files from disk.
 */
extension XCTestCase {
	
	class var testsDirectory: String {
		let dir = #file as NSString
		let proj = ((dir.deletingLastPathComponent as NSString).deletingLastPathComponent as NSString).deletingLastPathComponent as NSString
		return proj.appendingPathComponent("fhir-parser/downloads")
	}
	
	public func readJSONFile(_ filename: String, directory: String? = nil) throws -> FHIRJSON {
		let dir = directory ?? type(of: self).testsDirectory
		XCTAssertTrue(FileManager.default.fileExists(atPath: dir), "You must either first download the FHIR spec or manually adjust `XCTestCase.testsDirectory` to point to your FHIR download directory")
		
		let path = (dir as NSString).appendingPathComponent(filename)
		let data = try Data(contentsOf: URL(fileURLWithPath: path))
		let json = try JSONSerialization.jsonObject(with: data, options: []) as? FHIRJSON
		if let json = json {
			return json
		}
		throw FHIRError.error("Unable to decode «\(path)» to JSON")
	}
}

