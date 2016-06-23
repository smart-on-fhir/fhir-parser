//
//  {{ class.name }}Tests.swift
//  SwiftFHIR
//
//  Generated from FHIR {{ info.version }} on {{ info.date }}.
//  {{ info.year }}, SMART Health IT.
//

import XCTest
import SwiftFHIR


class {{ class.name }}Tests: XCTestCase {
	
	func instantiateFrom(filename filename: String) throws -> {{ class.name }} {
		return instantiateFrom(json: try readJSONFile(filename))
	}
	
	func instantiateFrom(json json: FHIRJSON) -> {{ class.name }} {
		let instance = {{ class.name }}(json: json)
		XCTAssertNotNil(instance, "Must have instantiated a test instance")
		return instance
	}
	
{%- for tcase in tests %}
	
	func test{{ class.name }}{{ loop.index }}() {
		do {
			let instance = try run{{ class.name }}{{ loop.index }}()
			try run{{ class.name }}{{ loop.index }}(instance.asJSON())
		}
		catch {
			XCTAssertTrue(false, "Must instantiate and test {{ class.name }} successfully, but threw")
		}
	}
	
	func run{{ class.name }}{{ loop.index }}(json: FHIRJSON? = nil) throws -> {{ class.name }} {
		let inst = (nil != json) ? instantiateFrom(json: json!) : try instantiateFrom(filename: "{{ tcase.filename }}")
		{% for onetest in tcase.tests %}
		{%- if "String" == onetest.klass.name %}
		XCTAssertEqual(inst.{{ onetest.path }}, "{{ onetest.value|replace('"', '\\"') }}")
		{%- else %}{% if "NSDecimalNumber" == onetest.klass.name %}
		XCTAssertEqual(inst.{{ onetest.path }}, NSDecimalNumber(string: "{{ onetest.value }}"))
		{%- else %}{% if "Int" == onetest.klass.name or "Double" == onetest.klass.name %}
		XCTAssertEqual(inst.{{ onetest.path }}, {{ onetest.value }})
		{%- else %}{% if "UInt" == onetest.klass.name %}
		XCTAssertEqual(inst.{{ onetest.path }}, UInt({{ onetest.value }}))
		{%- else %}{% if "Bool" == onetest.klass.name %}
		XCTAssert{% if onetest.value %}True{% else %}False{% endif %}(inst.{{ onetest.path }})
		{%- else %}{% if "Date" == onetest.klass.name or "Time" == onetest.klass.name or "DateTime" == onetest.klass.name or "Instant" == onetest.klass.name %}
		XCTAssertEqual(inst.{{ onetest.path }}.description, "{{ onetest.value }}")
		{%- else %}{% if "NSURL" == onetest.klass.name %}
		XCTAssertEqual(inst.{{ onetest.path }}.absoluteString, "{{ onetest.value }}")
		{%- else %}{% if "Base64Binary" == onetest.klass.name %}
		XCTAssertEqual(inst.{{ onetest.path }}, Base64Binary(value: "{{ onetest.value }}"))
		{%- else %}
		// Don't know how to create unit test for "{{ onetest.path }}", which is a {{ onetest.klass.name }}
		{%- endif %}{% endif %}{% endif %}{% endif %}{% endif %}{% endif %}{% endif %}{% endif %}
		{%- endfor %}
		
		return inst
	}
{%- endfor %}
}

