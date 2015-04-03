//
//  {{ class.name }}Tests.swift
//  SwiftFHIR
//
//  Generated from FHIR {{ info.version }} on {{ info.date }}.
//  {{ info.year }}, SMART Health IT.
//

import XCTest
import SwiftFHIR


class {{ class.name }}Tests: FHIRModelTestCase
{
	func instantiateFrom(# filename: String) -> {{ class.name }} {
		return instantiateFrom(json: readJSONFile(filename)!)
	}
	
	func instantiateFrom(# json: FHIRJSON) -> {{ class.name }} {
		let instance = {{ class.name }}(json: json)
		XCTAssertNotNil(instance, "Must have instantiated a test instance")
		return instance
	}
	
{%- for tcase in tests %}
	
	func test{{ class.name }}{{ loop.index }}() {
		let instance = test{{ class.name }}{{ loop.index }}_impl()
		test{{ class.name }}{{ loop.index }}_impl(json: instance.asJSON())
	}
	
	func test{{ class.name }}{{ loop.index }}_impl(json: FHIRJSON? = nil) -> {{ class.name }} {
		let inst = (nil != json) ? instantiateFrom(json: json!) : instantiateFrom(filename: "{{ tcase.filename }}")
		{% for onetest in tcase.tests %}
		{%- if "String" == onetest.klass.name %}
		XCTAssertEqual(inst.{{ onetest.path }}, "{{ onetest.value|replace('"', '\\"') }}")
		{%- else %}{% if "NSDecimalNumber" == onetest.klass.name %}
		XCTAssertEqual(inst.{{ onetest.path }}, NSDecimalNumber(string: "{{ onetest.value }}"))
		{%- else %}{% if "Int" == onetest.klass.name or "Double" == onetest.klass.name %}
		XCTAssertEqual(inst.{{ onetest.path }}, {{ onetest.value }})
		{%- else %}{% if "Bool" == onetest.klass.name %}
		XCTAssert{% if onetest.value %}True{% else %}False{% endif %}(inst.{{ onetest.path }})
		{%- else %}{% if "Date" == onetest.klass.name or "Time" == onetest.klass.name or "DateTime" == onetest.klass.name or "Instant" == onetest.klass.name %}
		XCTAssertEqual(inst.{{ onetest.path }}.description, "{{ onetest.value }}")
		{%- else %}{% if "NSURL" == onetest.klass.name %}
		XCTAssertEqual(inst.{{ onetest.path }}.absoluteString!, "{{ onetest.value }}")
		{%- else %}
		// Don't know how to create unit test for "{{ onetest.path }}", which is a {{ onetest.klass.name }}
		{%- endif %}{% endif %}{% endif %}{% endif %}{% endif %}{% endif %}
		{%- endfor %}
		
		return inst
	}
{%- endfor %}
}

