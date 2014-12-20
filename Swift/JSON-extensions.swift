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
		let parsed = ISODateParser.sharedParser.dateFromString(json)
		self.init(timeInterval: 0, sinceDate: parsed ?? NSDate())
	}
	
	public class func dateFromISOString(string: String) -> NSDate? {
		return ISODateParser.sharedParser.dateFromString(string)
	}
	
	public func isoDateString() -> String {
		return ISODateParser.sharedParser.isoDateStringFromDate(self)
	}
	
	public func isoDateTimeString() -> String {
		return ISODateParser.sharedParser.isoDateTimeStringFromDate(self)
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

extension NSDecimalNumber
{
	/*
		Takes an NSNumber, usually decoded from JSON, and creates an NSDecimalNumber instance
	
		We're using a string format approach using "%.15g" since NSJSONFormatting returns NSNumber objects instantiated
		with Double() or Int(). In the former case this causes precision issues (e.g. try 8.7). Unfortunately, some
		doubles with 16 and 17 significant digits will be truncated (e.g. a longitude of "4.844614000123024").
	
		TODO: improve to avoid double precision issues
	 */
	public convenience init(json: NSNumber) {
		if let periodIdx = find(json.stringValue, ".") {
			self.init(string: NSString(format: "%.15g", json.doubleValue))
		}
		else {
			self.init(string: "\(json)")
		}
	}
}

extension Base64Binary {
	public init(json: String) {
		self.init(value: json)
	}
}


/**
	Given a string, tries to figure out which date is specified and returns an NSDate.
	
	This class can be used as a singleton via its `sharedParser` class property.
	TODO: For now only checks a handful of formats, this can be vastly improved
 */
class ISODateParser
{
	/// The singleton instance
	class var sharedParser: ISODateParser {
		struct Static {
			static let instance = ISODateParser()
		}
		return Static.instance
	}
	
	/// Full ISO format: yyyy-MM-dd'T'HH:mm:ssZ
	let isoDateTimeFormatter: NSDateFormatter
	
	/// Full ISO format minus TZ: yyyy-MM-dd'T'HH:mm:ss
	let isoLocalDateTimeFormatter: NSDateFormatter
	
	/// Finds year-month-day
	let isoDateFormatter: NSDateFormatter
	
	/// Finds year-month
	let isoYearMonthFormatter: NSDateFormatter
	
	/// Finds year only
	let isoYearFormatter: NSDateFormatter
	
	init() {
		isoDateTimeFormatter = NSDateFormatter()
		isoDateTimeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
		isoDateTimeFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
		isoDateTimeFormatter.calendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)
		
		isoLocalDateTimeFormatter = NSDateFormatter()
		isoLocalDateTimeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
		isoLocalDateTimeFormatter.timeZone = NSTimeZone.localTimeZone()
		isoLocalDateTimeFormatter.calendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)
		
		isoDateFormatter = NSDateFormatter()
		isoDateFormatter.dateFormat = "yyyy-MM-dd"
		isoDateFormatter.timeZone = NSTimeZone.localTimeZone()
		isoDateFormatter.calendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)
		
		isoYearMonthFormatter = NSDateFormatter()
		isoYearMonthFormatter.dateFormat = "yyyy-MM"
		isoYearMonthFormatter.timeZone = NSTimeZone.localTimeZone()
		isoYearMonthFormatter.calendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)
		
		isoYearFormatter = NSDateFormatter()
		isoYearFormatter.dateFormat = "yyyy"
		isoYearFormatter.timeZone = NSTimeZone.localTimeZone()
		isoYearFormatter.calendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)
	}
	
	
	// MARK: - Parsing
	
	func dateFromString(string: String) -> NSDate? {
		var date = isoDateTimeFormatter.dateFromString(string)
		if nil == date {
			date = isoLocalDateTimeFormatter.dateFromString(string)
		}
		if nil == date {
			date = isoDateFormatter.dateFromString(string)
		}
		if nil == date {
			date = isoYearMonthFormatter.dateFromString(string)
		}
		if nil == date {
			date = isoYearFormatter.dateFromString(string)
		}
		
		return date
	}
	
	func isoDateStringFromDate(date: NSDate) -> String {
		return isoDateFormatter.stringFromDate(date)
	}
	
	func isoDateTimeStringFromDate(date: NSDate) -> String {
		return isoDateTimeFormatter.stringFromDate(date)
	}
}

