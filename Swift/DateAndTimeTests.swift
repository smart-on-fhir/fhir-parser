//
//  DateAndTimeTests.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 1/19/15.
//  2015, SMART Platforms.
//

import XCTest
import SwiftFHIR


class DateTests: XCTestCase
{
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
}


class TimeTests: XCTestCase
{
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
		
		t = Time(string: "18:44:88")
		XCTAssertFalse(nil == t)
		XCTAssertEqual(UInt8(18), t!.hour)
		XCTAssertEqual(UInt8(44), t!.minute)
		XCTAssertTrue(nil == t!.second)
		
		t = Time(string: "18:44:02")
		XCTAssertFalse(nil == t)
		XCTAssertEqual(UInt8(18), t!.hour)
		XCTAssertEqual(UInt8(44), t!.minute)
		XCTAssertEqual(2.0, t!.second!)
		
		t = Time(string: "18:44:02.2912")
		XCTAssertFalse(nil == t)
		XCTAssertEqual(UInt8(18), t!.hour)
		XCTAssertEqual(UInt8(44), t!.minute)
		XCTAssertEqual(2.2912, t!.second!)
		
		t = Time(string: "18:74:28.0381")
		XCTAssertTrue(nil == t)
		
//		t = Time(string: "18:-32:28.0381")		// this causes a weird crash in a code section that isn't run
//		XCTAssertTrue(nil == t)
		
		t = Time(string: "18:44:-28.0381")
		XCTAssertFalse(nil == t)
		XCTAssertEqual(UInt8(18), t!.hour)
		XCTAssertEqual(UInt8(44), t!.minute)
		XCTAssertTrue(nil == t!.second)
		
		t = Time(string: "abc")
		XCTAssertTrue(nil == t)
	}
}


class DateTimeTests: XCTestCase
{
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
}


class InstantTests: XCTestCase
{
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
}

