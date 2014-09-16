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
	{%- if "String" == onetest.class %}	
		XCTAssertEqual(inst!.{{ onetest.path }}, "{{ onetest.value|replace('"', '\\"') }}")
	{%- else %}{% if "Int" == onetest.class or "Double" == onetest.class or "NSDecimalNumber" == onetest.class %}
		XCTAssertEqual(inst!.{{ onetest.path }}, {{ onetest.value }})
	{%- else %}{% if "Bool" == onetest.class %}
		{%- if onetest.value %}
		XCTAssertTrue(inst!.{{ onetest.path }})
		{%- else %}
		XCTAssertFalse(inst!.{{ onetest.path }})
		{%- endif %}
	{%- else %}{% if "NSDate" == onetest.class %}
		XCTAssertEqual(inst!.{{ onetest.path }}, NSDate.dateFromISOString("{{ onetest.value }}"))
	{%- else %}{% if "NSURL" == onetest.class %}
		XCTAssertEqual(inst!.{{ onetest.path }}, NSURL(string: "{{ onetest.value }}"))
	{%- else %}
		# Don't know how to create unit test for "{{ onetest.path }}", which is a {{ onetest.class }}
	{%- endif %}{% endif %}{% endif %}{% endif %}{% endif %}
	{%- endfor %}
	}
{%- endfor %}
}

