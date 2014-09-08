//
//  {{ class }}Tests.swift
//  {{ class }}Tests
//
//  Generated from FHIR {{ info.version }} on {{ info.date }}.
//  Copyright (c) {{ info.year }} SMART Platforms. All rights reserved.
//

import Cocoa
import XCTest
import SwiftFHIR


class {{ class }}Tests: FHIRModelTestCase
{
	func instantiateFrom(filename: String) -> {{ class }}? {
		let json = readJSONFile(filename)
		let instance = {{ class }}(json: json)
		XCTAssertNotNil(instance, "Must have instantiated a test instance")
		return instance
	}
	
{%- for tcase in tests %}
	
	func test{{ class }}{{ loop.index }}() {
		let inst = instantiateFrom("{{ tcase.filename }}")
		XCTAssertNotNil(inst, "Must have instantiated a {{ class }} instance")
	{% for onetest in tcase.tests %}	
		XCTAssertEqual(inst!.{{ onetest.path }}, {{ onetest.expr | replace("\n", "\\n") }})
	{%- endfor %}
	}
{%- endfor %}
}

