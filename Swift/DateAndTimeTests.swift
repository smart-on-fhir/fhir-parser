//
//  DateAndTimeTests.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 1/19/15.
//  2015, SMART Health IT.
//

import XCTest
import SwiftFHIR


class DateTests: XCTestCase {
	
	func testParsing() {
		var d = Date(string: "2015")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.year)
		XCTAssertTrue(nil == d!.month)
		XCTAssertTrue(nil == d!.day)
		
		d = Date(string: "2015-83")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.year)
		XCTAssertTrue(nil == d!.month)
		XCTAssertTrue(nil == d!.day)
		
		d = Date(string: "2015-03")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.year)
		XCTAssertEqual(UInt8(3), d!.month!)
		XCTAssertTrue(nil == d!.day)
		
		d = Date(string: "2015-03-54")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.year)
		XCTAssertEqual(UInt8(3), d!.month!)
		XCTAssertTrue(nil == d!.day)
		
		d = Date(string: "2015-03-28")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.year)
		XCTAssertEqual(UInt8(3), d!.month!)
		XCTAssertEqual(UInt8(28), d!.day!)
		
		d = Date(string: "abc")
		XCTAssertTrue(nil == d)
		
		d = Date(string: "201512")
		XCTAssertTrue(nil == d)
		
		d = Date(string: "2015-123-456")!
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.year)
		XCTAssertTrue(nil == d!.month)
		XCTAssertTrue(nil == d!.day)
	}
	
	func testComparisons() {
		var a = Date(string: "2014")!
		var b = Date(string: "1914")!
		XCTAssertTrue(a > b)
		XCTAssertFalse(a == b)
		XCTAssertTrue(a == a)
		
		a = Date(string: "2014-12")!
		b = Date(string: "2014-11")!
		XCTAssertTrue(a > b)
		XCTAssertFalse(a == b)
		XCTAssertTrue(a == a)
		
		a = Date(string: "2014-11-25")!
		b = Date(string: "2014-11-24")!
		XCTAssertTrue(a > b)
		XCTAssertFalse(a == b)
		XCTAssertTrue(a == a)
		
		a = Date(string: "2014-11-24")!
		b = Date(string: "1914-11-24")!
		XCTAssertTrue(a > b)
		XCTAssertFalse(a == b)
		XCTAssertTrue(a == a)
		
		a = Date(string: "2014-12-24")!
		b = Date(string: "2014-11-24")!
		XCTAssertTrue(a > b)
		XCTAssertFalse(a == b)
		XCTAssertTrue(a == a)
	}
	
	func testConversion() {
		let date = Date(string: "1981-03-28")!
		let ns = date.nsDate
		XCTAssertEqual(date, ns.fhir_asDate(), "Conversion to NSDate and back again must not alter `Date`")
	}
}


class TimeTests: XCTestCase {
	
	func testParsing() {
		var t = Time(string: "18")
		XCTAssertTrue(nil == t)
		
		t = Time(string: "18:72")
		XCTAssertTrue(nil == t)
		
		t = Time(string: "25:44")
		XCTAssertTrue(nil == t)
		
		t = Time(string: "18:44")
		XCTAssertFalse(nil == t)
		XCTAssertEqual(UInt8(18), t!.hour)
		XCTAssertEqual(UInt8(44), t!.minute)
		XCTAssertTrue(nil == t!.second)
		
		t = Time(string: "00:00:00")
		XCTAssertFalse(nil == t)
		XCTAssertEqual(UInt8(0), t!.hour)
		XCTAssertEqual(UInt8(0), t!.minute)
		XCTAssertEqual(0.0, t!.second)
		
		t = Time(string: "18:44:88")
		XCTAssertFalse(nil == t)
		XCTAssertEqual(UInt8(18), t!.hour)
		XCTAssertEqual(UInt8(44), t!.minute)
		XCTAssertTrue(nil == t!.second)
		
		t = Time(string: "18:44:-4")
		XCTAssertFalse(nil == t)
		XCTAssertEqual(UInt8(18), t!.hour)
		XCTAssertEqual(UInt8(44), t!.minute)
		XCTAssertTrue(nil == t!.second)
		
		t = Time(string: "18:44:02")
		XCTAssertFalse(nil == t)
		XCTAssertEqual(UInt8(18), t!.hour)
		XCTAssertEqual(UInt8(44), t!.minute)
		XCTAssertEqual(2.0, t!.second)
		
		t = Time(string: "18:44:02.2912")
		XCTAssertFalse(nil == t)
		XCTAssertEqual(UInt8(18), t!.hour)
		XCTAssertEqual(UInt8(44), t!.minute)
		XCTAssertEqual(2.2912, t!.second)
		
		t = Time(string: "18:74:28.0381")
		XCTAssertTrue(nil == t)
		
		t = Time(string: "18:-32:28.0381")
		XCTAssertTrue(nil == t)
		
		t = Time(string: "18:44:-28.0381")
		XCTAssertFalse(nil == t)
		XCTAssertEqual(UInt8(18), t!.hour)
		XCTAssertEqual(UInt8(44), t!.minute)
		XCTAssertTrue(nil == t!.second)
		
		t = Time(string: "18:44:28.038100")
		XCTAssertFalse(nil == t)
		XCTAssertEqual(UInt8(18), t!.hour)
		XCTAssertEqual(UInt8(44), t!.minute)
		XCTAssertEqual(28.0381, t!.second)
		XCTAssertEqual(t!.description, "18:44:28.038100", "must preserve precision")
		
		t = Time(string: "abc")
		XCTAssertTrue(nil == t)
	}
	
	func testComparisons() {
		var a = Time(string: "19:12")!
		var b = Time(string: "19:11")!
		XCTAssertTrue(a > b)
		XCTAssertFalse(a == b)
		XCTAssertTrue(a == a)
		
		a = Time(string: "19:11:04")!
		b = Time(string: "19:11:03")!
		XCTAssertTrue(a > b)
		XCTAssertFalse(a == b)
		XCTAssertTrue(a == a)
		
		a = Time(string: "19:11:04")!
		b = Time(string: "07:11:05")!
		XCTAssertTrue(a > b)
		XCTAssertFalse(a == b)
		XCTAssertTrue(a == a)
		
		a = Time(string: "19:00:04")!
		b = Time(string: "07:11:05")!
		XCTAssertTrue(a > b)
		XCTAssertFalse(a == b)
		XCTAssertTrue(a == a)
		
		a = Time(string: "19:11:04")!
		b = Time(string: "19:11")!
		XCTAssertTrue(a > b)
		XCTAssertFalse(a == b)
		XCTAssertTrue(a == a)
		
		a = Time(string: "19:11:04.0002")!
		b = Time(string: "19:11:04")!
		XCTAssertTrue(a > b)
		XCTAssertFalse(a == b)
		XCTAssertTrue(a == a)
		
		a = Time(string: "19:11:04.0002")!
		b = Time(hour: 19, minute: 11, second: 4.0002)
		XCTAssertFalse(a > b)
		XCTAssertTrue(a == b)
		
		a = Time(string: "19:11:04.000200")!
		b = Time(hour: 19, minute: 11, second: 4.0002)
		XCTAssertFalse(a > b)
		XCTAssertFalse(a < b)
		XCTAssertFalse(a == b)
	}
	
	func testConversion() {
		let time = Time(string: "15:42:03")!
		let ns = time.nsDate
		XCTAssertEqual(time, ns.fhir_asTime(), "Conversion to NSDate and back again must not alter `Time`")
	}
}


class DateTimeTests: XCTestCase {
	
	func testParseAllCorrect() {
		var d = DateTime(string: "2015")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.date.year)
		XCTAssertTrue(nil == d!.date.month)
		XCTAssertTrue(nil == d!.time)
		XCTAssertTrue(nil == d!.timeZone)
		
		d = DateTime(string: "2015-03")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.date.year)
		XCTAssertEqual(UInt8(3), d!.date.month!)
		XCTAssertTrue(nil == d!.date.day)
		XCTAssertTrue(nil == d!.time)
		XCTAssertTrue(nil == d!.timeZone)
		
		d = DateTime(string: "2015-03-28")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.date.year)
		XCTAssertEqual(UInt8(3), d!.date.month!)
		XCTAssertEqual(UInt8(28), d!.date.day!)
		XCTAssertTrue(nil == d!.time)
		XCTAssertTrue(nil == d!.timeZone)
		
		d = DateTime(string: "2015-03-28T02:33")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.date.year)
		XCTAssertEqual(UInt8(3), d!.date.month!)
		XCTAssertEqual(UInt8(28), d!.date.day!)
		XCTAssertFalse(nil == d!.time)
		XCTAssertEqual(UInt8(2), d!.time!.hour)
		XCTAssertEqual(UInt8(33), d!.time!.minute)
		XCTAssertTrue(nil == d!.time!.second)
		XCTAssertFalse(nil == d!.timeZone)
		XCTAssertEqual(NSTimeZone.localTimeZone(), d!.timeZone!, "Must default to the local timezone")
		
		d = DateTime(string: "2015-03-28T02:33:29")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.date.year)
		XCTAssertEqual(UInt8(3), d!.date.month!)
		XCTAssertEqual(UInt8(28), d!.date.day!)
		XCTAssertFalse(nil == d!.time)
		XCTAssertEqual(UInt8(2), d!.time!.hour)
		XCTAssertEqual(UInt8(33), d!.time!.minute)
		XCTAssertEqual(29, d!.time!.second!)
		XCTAssertFalse(nil == d!.timeZone)
		XCTAssertEqual(NSTimeZone.localTimeZone(), d!.timeZone!, "Should default to local time zone but have \(d!.timeZone)")
		
		d = DateTime(string: "2015-03-28T02:33:29+01:00")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.date.year)
		XCTAssertEqual(UInt8(3), d!.date.month!)
		XCTAssertEqual(UInt8(28), d!.date.day!)
		XCTAssertFalse(nil == d!.time)
		XCTAssertEqual(UInt8(2), d!.time!.hour)
		XCTAssertEqual(UInt8(33), d!.time!.minute)
		XCTAssertEqual(29, d!.time!.second!)
		XCTAssertFalse(nil == d!.timeZone)
		XCTAssertTrue(3600 == d!.timeZone!.secondsFromGMT, "Should be 3600 seconds ahead, but am \(d!.timeZone!.secondsFromGMT) seconds")
		
		d = DateTime(string: "2015-03-28T02:33:29-05:00")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.date.year)
		XCTAssertEqual(UInt8(3), d!.date.month!)
		XCTAssertEqual(UInt8(28), d!.date.day!)
		XCTAssertFalse(nil == d!.time)
		XCTAssertEqual(UInt8(2), d!.time!.hour)
		XCTAssertEqual(UInt8(33), d!.time!.minute)
		XCTAssertEqual(29, d!.time!.second!)
		XCTAssertFalse(nil == d!.timeZone)
		XCTAssertTrue(-18000 == d!.timeZone!.secondsFromGMT, "Should be 18000 seconds ahead, but am \(d!.timeZone!.secondsFromGMT) seconds")
		
		d = DateTime(string: "2015-03-28T02:33:29.1285-05:00")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.date.year)
		XCTAssertEqual(UInt8(3), d!.date.month!)
		XCTAssertEqual(UInt8(28), d!.date.day!)
		XCTAssertFalse(nil == d!.time)
		XCTAssertEqual(UInt8(2), d!.time!.hour)
		XCTAssertEqual(UInt8(33), d!.time!.minute)
		XCTAssertEqual(29.1285, d!.time!.second!)
		XCTAssertFalse(nil == d!.timeZone)
		XCTAssertTrue(-18000 == d!.timeZone!.secondsFromGMT, "Should be 18000 seconds ahead, but am \(d!.timeZone!.secondsFromGMT) seconds")
		
		d = DateTime(string: "2015-03-28T02:33:29.1285-05:30")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.date.year)
		XCTAssertEqual(UInt8(3), d!.date.month!)
		XCTAssertEqual(UInt8(28), d!.date.day!)
		XCTAssertFalse(nil == d!.time)
		XCTAssertEqual(UInt8(2), d!.time!.hour)
		XCTAssertEqual(UInt8(33), d!.time!.minute)
		XCTAssertEqual(29.1285, d!.time!.second!)
		XCTAssertFalse(nil == d!.timeZone)
		XCTAssertTrue(-19800 == d!.timeZone!.secondsFromGMT, "Should be 19800 seconds ahead, but am \(d!.timeZone!.secondsFromGMT) seconds")
		
		d = DateTime(string: "2015-03-28T02:33:29.128500-05:30")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.date.year)
		XCTAssertEqual(UInt8(3), d!.date.month!)
		XCTAssertEqual(UInt8(28), d!.date.day!)
		XCTAssertFalse(nil == d!.time)
		XCTAssertEqual(UInt8(2), d!.time!.hour)
		XCTAssertEqual(UInt8(33), d!.time!.minute)
		XCTAssertEqual(29.1285, d!.time!.second!)
		XCTAssertEqual("2015-03-28T02:33:29.128500-05:30", d!.description)
		XCTAssertFalse(nil == d!.timeZone)
		XCTAssertTrue(-19800 == d!.timeZone!.secondsFromGMT, "Should be 19800 seconds ahead, but am \(d!.timeZone!.secondsFromGMT) seconds")
		
		d = DateTime(string: "2015-03-28T02:33:29-05")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.date.year)
		XCTAssertEqual(UInt8(3), d!.date.month!)
		XCTAssertEqual(UInt8(28), d!.date.day!)
		XCTAssertFalse(nil == d!.time)
		XCTAssertEqual(UInt8(2), d!.time!.hour)
		XCTAssertEqual(UInt8(33), d!.time!.minute)
		XCTAssertEqual(29, d!.time!.second!)
		XCTAssertFalse(nil == d!.timeZone)
		XCTAssertTrue(-18000 == d!.timeZone!.secondsFromGMT, "Should be 18000 seconds ahead, but am \(d!.timeZone!.secondsFromGMT) seconds")
		
		d = DateTime(string: "2015-03-28T02:33:29.1285-0500")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.date.year)
		XCTAssertEqual(UInt8(3), d!.date.month!)
		XCTAssertEqual(UInt8(28), d!.date.day!)
		XCTAssertFalse(nil == d!.time)
		XCTAssertEqual(UInt8(2), d!.time!.hour)
		XCTAssertEqual(UInt8(33), d!.time!.minute)
		XCTAssertEqual(29.1285, d!.time!.second!)
		XCTAssertFalse(nil == d!.timeZone)
		XCTAssertTrue(-18000 == d!.timeZone!.secondsFromGMT, "Should be 18000 seconds ahead, but am \(d!.timeZone!.secondsFromGMT) seconds")
		
		d = DateTime(string: "2015-03-28T02:33:29.1285-0530")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.date.year)
		XCTAssertEqual(UInt8(3), d!.date.month!)
		XCTAssertEqual(UInt8(28), d!.date.day!)
		XCTAssertFalse(nil == d!.time)
		XCTAssertEqual(UInt8(2), d!.time!.hour)
		XCTAssertEqual(UInt8(33), d!.time!.minute)
		XCTAssertEqual(29.1285, d!.time!.second!)
		XCTAssertFalse(nil == d!.timeZone)
		XCTAssertTrue(-19800 == d!.timeZone!.secondsFromGMT, "Should be 19800 seconds ahead, but am \(d!.timeZone!.secondsFromGMT) seconds")
	}
	
	func testParseSomeFails() {
		var d: DateTime?
//		d = DateTime(string: "02015")	// should probably fail, currently doesn't
//		XCTAssertTrue(nil == d)
		
		d = DateTime(string: "2015-103")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.date.year)
		XCTAssertTrue(nil == d!.date.month)
		XCTAssertTrue(nil == d!.date.day)
		XCTAssertTrue(nil == d!.time)
		XCTAssertTrue(nil == d!.timeZone)
		
		d = DateTime(string: "2015-03-208")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.date.year)
		XCTAssertEqual(UInt8(3), d!.date.month!)
		XCTAssertTrue(nil == d!.date.day)
		XCTAssertTrue(nil == d!.time)
		XCTAssertTrue(nil == d!.timeZone)
		
		d = DateTime(string: "2015-03-28 02:33")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.date.year)
		XCTAssertEqual(UInt8(3), d!.date.month!)
		XCTAssertEqual(UInt8(28), d!.date.day!)
		XCTAssertTrue(nil == d!.time)
		XCTAssertTrue(nil == d!.timeZone)
		
		d = DateTime(string: "2015-03-28T02-33-29")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.date.year)
		XCTAssertEqual(UInt8(3), d!.date.month!)
		XCTAssertEqual(UInt8(28), d!.date.day!)
		XCTAssertTrue(nil == d!.time)
		XCTAssertTrue(nil == d!.timeZone)
		
		d = DateTime(string: "2015-03-28T02:33:29GMT")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.date.year)
		XCTAssertEqual(UInt8(3), d!.date.month!)
		XCTAssertEqual(UInt8(28), d!.date.day!)
		XCTAssertFalse(nil == d!.time)
		XCTAssertEqual(UInt8(2), d!.time!.hour)
		XCTAssertEqual(UInt8(33), d!.time!.minute)
		XCTAssertEqual(29, d!.time!.second!)
		XCTAssertFalse(nil == d!.timeZone)
		XCTAssertEqual(NSTimeZone.localTimeZone(), d!.timeZone!, "Should default to local time zone but have \(d!.timeZone)")
	}
	
	func testComparisons() {
		var a = DateTime(string: "2014")!
		var b = DateTime(string: "1914")!
		XCTAssertTrue(a > b)
		XCTAssertFalse(a == b)
		XCTAssertTrue(a == a)
		
		a = DateTime(string: "2015-03-28T03:11")!
		b = DateTime(string: "2015-03-28T03:10")!
		XCTAssertTrue(a > b)
		XCTAssertFalse(a == b)
		XCTAssertTrue(a == a)
		
		a = DateTime(string: "2015-03-28T03:11:04")!
		b = DateTime(string: "2015-03-28T03:11:03")!
		XCTAssertTrue(a > b)
		XCTAssertFalse(a == b)
		XCTAssertTrue(a == a)
		
		a = DateTime(string: "2015-03-28T03:11:04")!
		b = DateTime(string: "2015-03-28T03:11:04")!
		XCTAssertFalse(a > b)
		XCTAssertTrue(a == b)
		XCTAssertTrue(a == a)
		
		a = DateTime(string: "2015-03-28T03:11:04Z")!
		b = DateTime(string: "1915-03-28T03:11:04Z")!
		XCTAssertTrue(a > b)
		XCTAssertFalse(a == b)
		XCTAssertTrue(a == a)
		
		a = DateTime(string: "2015-03-28T03:11:04Z")!
		b = DateTime(string: "2015-03-28T03:11:04+00:00")!
		XCTAssertFalse(a > b)
		XCTAssertTrue(a == b)
		XCTAssertTrue(a == a)
		
		a = DateTime(string: "2015-03-28T03:11+00:00")!
		b = DateTime(string: "2015-03-28T03:17+01:00")!
		XCTAssertTrue(a > b)
		XCTAssertFalse(a == b)
		XCTAssertTrue(a == a)
		
		a = DateTime(string: "2015-03-27T22:12:44-05:00")!
		b = DateTime(string: "2015-03-28T03:12:43-00:00")!
		XCTAssertTrue(a > b)
		XCTAssertFalse(a == b)
		XCTAssertTrue(a == a)
		
		a = DateTime(string: "2015-03-28T05:11:44.3+01:00")!
		b = DateTime(string: "2015-03-27T23:11:44.3-05:00")!
		XCTAssertFalse(a > b)
		XCTAssertTrue(a == b)
		XCTAssertTrue(a == a)
	}
	
	func testConversion() {
		let dt = DateTime(string: "1981-03-28T15:42:03")!
		let ns = dt.nsDate
		XCTAssertEqual(dt, ns.fhir_asDateTime(), "Conversion to NSDate and back again must not alter `DateTime`")
		
		let dt2 = DateTime(string: "1981-03-28T15:42:03-0100")!
		let ns2 = dt2.nsDate
		XCTAssertEqual(dt2, ns2.fhir_asDateTime(), "Conversion to NSDate and back again must not alter `DateTime`")
	}
}


class InstantTests: XCTestCase {
	
	func testParseSuccess() {
		var d = Instant(string: "2015")
		XCTAssertTrue(nil == d)
		
		d = Instant(string: "2015-03")
		XCTAssertTrue(nil == d)
		
		d = Instant(string: "2015-03-28")
		XCTAssertTrue(nil == d)
		
		d = Instant(string: "2015-03-28T02:33")
		XCTAssertTrue(nil == d)
		
		d = Instant(string: "2015-03-28T02:33:29")
		XCTAssertTrue(nil == d)
		
		d = Instant(string: "2015-03-28T02:33:29+01:00")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.date.year)
		XCTAssertEqual(UInt8(3), d!.date.month!)
		XCTAssertEqual(UInt8(28), d!.date.day!)
		XCTAssertEqual(UInt8(2), d!.time.hour)
		XCTAssertEqual(UInt8(33), d!.time.minute)
		XCTAssertEqual(29, d!.time.second!)
		XCTAssertTrue(3600 == d!.timeZone.secondsFromGMT)
		
		d = Instant(string: "2015-03-28T02:33:29-05:00")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.date.year)
		XCTAssertEqual(UInt8(3), d!.date.month!)
		XCTAssertEqual(UInt8(28), d!.date.day!)
		XCTAssertEqual(UInt8(2), d!.time.hour)
		XCTAssertEqual(UInt8(33), d!.time.minute)
		XCTAssertEqual(29, d!.time.second!)
		XCTAssertTrue(-18000 == d!.timeZone.secondsFromGMT)
		
		d = Instant(string: "2015-03-28T02:33:29.1285-05:00")
		XCTAssertFalse(nil == d)
		XCTAssertEqual(2015, d!.date.year)
		XCTAssertEqual(UInt8(3), d!.date.month!)
		XCTAssertEqual(UInt8(28), d!.date.day!)
		XCTAssertEqual(UInt8(2), d!.time.hour)
		XCTAssertEqual(UInt8(33), d!.time.minute)
		XCTAssertEqual(29.1285, d!.time.second!)
		XCTAssertTrue(-18000 == d!.timeZone.secondsFromGMT)
	}
	
	func testComparisons() {
		var a = Instant(string: "2015-03-28T03:11:04Z")!
		var b = Instant(string: "1915-03-28T03:11:04Z")!
		XCTAssertTrue(a > b)
		XCTAssertFalse(a == b)
		XCTAssertTrue(a == a)
		
		a = Instant(string: "2015-03-28T03:11:04Z")!
		b = Instant(string: "2015-03-28T03:11:04+00:00")!
		XCTAssertFalse(a > b)
		XCTAssertTrue(a == b)
		XCTAssertTrue(a == a)
		
		a = Instant(string: "2015-03-28T03:11:44+00:00")!
		b = Instant(string: "2015-03-28T03:17:44+01:00")!
		XCTAssertTrue(a > b)
		XCTAssertFalse(a == b)
		XCTAssertTrue(a == a)
		
		a = Instant(string: "2015-03-27T22:12:44-05:00")!
		b = Instant(string: "2015-03-28T03:11:44-00:00")!
		XCTAssertTrue(a > b)
		XCTAssertFalse(a == b)
		XCTAssertTrue(a == a)
		
		a = Instant(string: "2015-03-28T05:11:44.3+01:00")!
		b = Instant(string: "2015-03-27T23:11:44.3-05:00")!
		XCTAssertFalse(a > b)
		XCTAssertTrue(a == b)
		XCTAssertTrue(a == a)
	}
	
	func testConversion() {
		let inst = Instant(string: "1981-03-28T15:42:03-0500")!
		let ns = inst.nsDate
		XCTAssertEqual(inst, ns.fhir_asInstant(), "Conversion to NSDate and back again must not alter `Instant`")
	}
	
	func testHttpDateParsing() {
		if let instant = Instant.fromHttpDate("Fri, 14 Aug 2009 14:45:31 GMT") {
			XCTAssertEqual(instant.date.year, 2009)
			XCTAssertEqual(instant.date.month, 8)
			XCTAssertEqual(instant.time.hour, 14)
			XCTAssertEqual(instant.time.minute, 45)
		}
		else {
			XCTAssertTrue(false, "Failed to parse perfectly fine HTTP date")
		}
		
		if let instant = Instant.fromHttpDate("Sun, 06 Nov 1994 08:49:37 GMT") {
			XCTAssertEqual(instant.date.year, 1994)
			XCTAssertEqual(instant.date.month, 11)
			XCTAssertEqual(instant.time.hour, 8)
			XCTAssertEqual(instant.time.minute, 49)
			XCTAssertEqual(instant.time.second, 37.0)
		}
		else {
			XCTAssertTrue(false, "Failed to parse perfectly fine HTTP date")
		}
		
		if let instant = Instant.fromHttpDate("Sunday, 06-Nov-94 08:49:37 GMT") {
			XCTAssertEqual(instant.date.year, 1994)
			XCTAssertEqual(instant.date.month, 11)
			XCTAssertEqual(instant.time.hour, 8)
			XCTAssertEqual(instant.time.minute, 49)
			XCTAssertEqual(instant.time.second, 37.0)
		}
		else {
			XCTAssertTrue(false, "Failed to parse perfectly fine HTTP date")
		}
		
		if let instant = Instant.fromHttpDate("Wed Nov 16 08:49:37 1994") {
			XCTAssertEqual(instant.date.year, 1994)
			XCTAssertEqual(instant.date.month, 11)
			XCTAssertEqual(instant.time.hour, 8)
			XCTAssertEqual(instant.time.minute, 49)
			XCTAssertEqual(instant.time.second, 37.0)
		}
		else {
			XCTAssertTrue(false, "Failed to parse perfectly fine HTTP date")
		}
	}
}

