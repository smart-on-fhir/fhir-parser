//
//  {{ class.name }}Tests.swift
//  RealmSwiftFHIR
//
//  Generated from FHIR {{ info.version }} on {{ info.date }}.
//  {{ info.year }}, SMART Health IT.
//
// Tweaked for RealmSupport by Ryan Baldwin, University Health Network.

import XCTest
import RealmSwift
import RealmSwiftFHIR


class {{ class.name }}Tests: XCTestCase, RealmPersistenceTesting {    
	var realm: Realm!

	override func setUp() {
		realm = makeRealm()
	}

	func instantiateFrom(filename: String) throws -> RealmSwiftFHIR.{{ class.name }} {
		return instantiateFrom(json: try readJSONFile(filename))
	}
	
	func instantiateFrom(json: FHIRJSON) -> RealmSwiftFHIR.{{ class.name }} {
		let instance = RealmSwiftFHIR.{{ class.name }}(json: json)
		XCTAssertNotNil(instance, "Must have instantiated a test instance")
		return instance
	}
	
{%- for tcase in tests %}
	
	func test{{ class.name }}{{ loop.index }}() {		
		var instance: RealmSwiftFHIR.{{ class.name }}?
		do {
			instance = try run{{ class.name }}{{ loop.index }}()
			try run{{ class.name }}{{ loop.index }}(instance!.asJSON()) 			
		}
		catch {
			XCTAssertTrue(false, "Must instantiate and test {{ class.name }} successfully, but threw")
		}

		test{{ class.name}}Realm{{ loop.index}}(instance: instance!)
	}

	func test{{ class.name}}Realm{{ loop.index }}(instance: RealmSwiftFHIR.{{class.name}}) {
		try! realm.write {
                realm.add(instance)
            }
        try! run{{ class.name }}{{ loop.index }}(realm.objects(RealmSwiftFHIR.{{ class.name }}.self).first!.asJSON())
        
        try! realm.write {
        	instance.implicitRules = "Rule #1"
            realm.add(instance, update: true)
        }
        XCTAssertEqual(1, realm.objects(RealmSwiftFHIR.{{ class.name }}.self).count)
        XCTAssertEqual("Rule #1", realm.objects(RealmSwiftFHIR.{{ class.name }}.self).first!.implicitRules)
        
        try! realm.write {
            realm.delete(instance)
        }
        XCTAssertEqual(0, realm.objects(RealmSwiftFHIR.Account.self).count)
	}
	
	@discardableResult
	func run{{ class.name }}{{ loop.index }}(_ json: FHIRJSON? = nil) throws -> RealmSwiftFHIR.{{ class.name }} {
		let inst = (nil != json) ? instantiateFrom(json: json!) : try instantiateFrom(filename: "{{ tcase.filename }}")
		{% for onetest in tcase.tests %}
		{%- if "String" == onetest.klass.name %}
		XCTAssertEqual(inst.{{ onetest.path }}, "{{ onetest.value|replace('"', '\\"') }}")
		{%- else %}{% if "RealmDecimal" == onetest.klass.name %}
		XCTAssertTrue(inst.{{ onetest.path }}! == RealmDecimal(string: "{{ onetest.value }}"))
		{%- else %}{% if "Int" == onetest.klass.name or "Double" == onetest.klass.name %}
		XCTAssertEqual(inst.{{ onetest.path }}, {{ onetest.value }})
		{%- else %}{% if "UInt" == onetest.klass.name %}
		XCTAssertEqual(inst.{{ onetest.path }}, UInt({{ onetest.value }}))
		{%- else %}{% if "Bool" == onetest.klass.name %}
		XCTAssert{% if onetest.value %}True{% else %}False{% endif %}(inst.{{ onetest.path }} ?? {% if onetest.value %}false{% else %}true{% endif %})
		{%- else %}{% if "FHIRDate" == onetest.klass.name or "FHIRTime" == onetest.klass.name or "DateTime" == onetest.klass.name or "Instant" == onetest.klass.name %}
		XCTAssertEqual(inst.{{ onetest.path }}{% if not onetest.array_item %}?{% endif %}.description, "{{ onetest.value }}")
		{%- else %}{% if "URL" == onetest.klass.name %}
		XCTAssertEqual(inst.{{ onetest.path }}{% if not onetest.array_item %}?{% endif %}.absoluteString, "{{ onetest.value }}")
		{%- else %}{% if "Base64Binary" == onetest.klass.name %}
		XCTAssertTrue(inst.{{ onetest.path }}! == Base64Binary(val: "{{ onetest.value }}"))
		{%- else %}
		// Don't know how to create unit test for "{{ onetest.path }}", which is a {{ onetest.klass.name }}
		{%- endif %}{% endif %}{% endif %}{% endif %}{% endif %}{% endif %}{% endif %}{% endif %}
		{%- endfor %}
		
		return inst
	}
{%- endfor %}
}

