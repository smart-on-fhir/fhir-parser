//
//  {{ class.name }}Tests.swift
//  SwiftFHIR
//
//  Generated from FHIR {{ info.version }} on {{ info.date }}.
//  {{ info.year }}, SMART Health IT.
//

import XCTest
#if !NO_MODEL_IMPORT
import Models
typealias SwiftFHIR{{ class.name }} = Models.{{ class.name }}
#else
import SwiftFHIR
typealias SwiftFHIR{{ class.name }} = SwiftFHIR.{{ class.name }}
#endif


class {{ class.name }}Tests: XCTestCase {
	
	func instantiateFrom(filename: String) throws -> SwiftFHIR{{ class.name }} {
		return try instantiateFrom(json: try readJSONFile(filename))
	}
	
	func instantiateFrom(json: FHIRJSON) throws -> SwiftFHIR{{ class.name }} {
		return try SwiftFHIR{{ class.name }}(json: json)
	}
	
{%- for tcase in tests %}
	
	func test{{ class.name }}{{ loop.index }}() {
		do {
			let instance = try run{{ class.name }}{{ loop.index }}()
			try run{{ class.name }}{{ loop.index }}(instance.asJSON())
		}
		catch let error {
			XCTAssertTrue(false, "Must instantiate and test {{ class.name }} successfully, but threw:\n---\n\(error)\n---")
		}
	}
	
	@discardableResult
	func run{{ class.name }}{{ loop.index }}(_ json: FHIRJSON? = nil) throws -> SwiftFHIR{{ class.name }} {
		let inst = (nil != json) ? try instantiateFrom(json: json!) : try instantiateFrom(filename: "{{ tcase.filename }}")
		{% for onetest in tcase.tests %}
		{%- if onetest.enum %}
		XCTAssertEqual(inst.{{ onetest.path }}, {{ onetest.enum }}(rawValue: "{{ onetest.value|replace('"', '\\"') }}")!)
		{%- else %}{% if "FHIRString" == onetest.klass.name %}
		XCTAssertEqual(inst.{{ onetest.path }}, "{{ onetest.value|replace('"', '\\"') }}")
		{%- else %}{% if "FHIRDecimal" == onetest.klass.name %}
		XCTAssertEqual(inst.{{ onetest.path }}, "{{ onetest.value }}")
		{%- else %}{% if "FHIRInteger" == onetest.klass.name %}
		XCTAssertEqual(inst.{{ onetest.path }}, {{ onetest.value }})
		{%- else %}{% if "FHIRBool" == onetest.klass.name %}
		XCTAssertEqual(inst.{{ onetest.path }}, {% if onetest.value %}true{% else %}false{% endif %})
		{%- else %}{% if "FHIRDate" == onetest.klass.name or "FHIRTime" == onetest.klass.name or "DateTime" == onetest.klass.name or "Instant" == onetest.klass.name %}
		XCTAssertEqual(inst.{{ onetest.path }}{% if not onetest.array_item %}?{% endif %}.description, "{{ onetest.value }}")
		{%- else %}{% if "FHIRURL" == onetest.klass.name %}
		XCTAssertEqual(inst.{{ onetest.path }}{% if not onetest.array_item %}?{% endif %}.absoluteString, "{{ onetest.value }}")
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

