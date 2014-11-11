//
//  JSON-extensions.swift
//  SMART-on-FHIR
//
//  Created by Pascal Pfiffner on 7/4/14.
//  2014, SMART Platforms.
//

import Foundation


extension NSDate {
	public convenience init(json: String) {
		let parsed = NSDate.dateFromISOString(json)
		self.init(timeInterval: 0, sinceDate: parsed ?? NSDate())
	}
	
	public class func dateFromISOString(string: String) -> NSDate? {
		var date = isoDateTimeFormatter().dateFromString(string)
		if nil == date {
			date = isoLocalDateTimeFormatter().dateFromString(string)
		}
		if nil == date {
			date = isoDateFormatter().dateFromString(string)
		}
		
		return date
	}
	
	public func isoDateString() -> String {
		return self.dynamicType.isoDateFormatter().stringFromDate(self)
	}
	
	public func isoDateTimeString() -> String {
		return self.dynamicType.isoDateTimeFormatter().stringFromDate(self)
	}
	
	
	// MARK: Date Formatter
	
	/**
	 *  Instantiates and returns an NSDateFormatter that understands ISO-8601 with timezone.
	 */
	public class func isoDateTimeFormatter() -> NSDateFormatter {
		let formatter = NSDateFormatter()							// class vars are not yet supported
		formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
		formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
		formatter.calendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)
		
		return formatter
	}
	
	/**
	 *  Instantiates and returns an NSDateFormatter that understands ISO-8601 WITHOUT timezone.
	 */
	public class func isoLocalDateTimeFormatter() -> NSDateFormatter {
		let formatter = NSDateFormatter()							// class vars are not yet supported
		formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
		formatter.timeZone = NSTimeZone.localTimeZone()
		formatter.calendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)
		
		return formatter
	}
	
	/**
	 *  Instantiates and returns an NSDateFormatter that understands ISO-8601 date only.
	 */
	public class func isoDateFormatter() -> NSDateFormatter {
		let formatter = NSDateFormatter()							// class vars are not yet supported
		formatter.dateFormat = "yyyy-MM-dd"
		formatter.timeZone = NSTimeZone.localTimeZone()
		formatter.calendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)
		
		return formatter
	}
}

extension NSURL {
	public convenience init?(json: String) {
		self.init(string: json)
	}
	
	public class func from(json: [String]) -> [NSURL] {
		var arr: [NSURL] = []
		for string in json {
			let url: NSURL? = NSURL(string: string)
			if nil != url {
				arr.append(url!)
			}
		}
		return arr
	}
}

extension NSDecimalNumber {
	public convenience init(json: NSNumber) {
		self.init(string: "\(json)")			// there is no "decimalValue" on NSNumber in Swift, so use a String
	}
}

