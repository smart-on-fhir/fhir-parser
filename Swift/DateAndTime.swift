//
//  DateAndTime.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 1/17/15.
//  2015, SMART Health IT.
//

import Foundation


/**
A protocol for all our date and time structs.
*/
protocol DateAndTime: CustomStringConvertible, Comparable, Equatable {
	
	var nsDate: NSDate { get }
}


/**
A date for use in human communication.

Month and day are optional and there are no timezones.
*/
public struct Date: DateAndTime {
	
	/// The year.
	public var year: Int
	
	/// The month of the year, maximum of 12.
	public var month: UInt8? {
		didSet {
			if month > 12 {
				month = nil
			}
		}
	}
	
	/// The day of the month; must be valid for the month (not enforced in code!).
	public var day: UInt8? {
		didSet {
			if day > 31 {
				day = nil
			}
		}
	}
	
	
	/**
	Dedicated initializer. Everything but the year is optional, invalid months or days will be ignored (however it is NOT checked whether
	the given month indeed contains the given day).
	
	- parameter year:  The year of the date
	- parameter month: The month of the year
	- parameter day:   The day of the month – your responsibility to ensure the month has the desired number of days; ignored if no month is
	                   given
	*/
	public init(year: Int, month: UInt8?, day: UInt8?) {
		self.year = year
		if month <= 12 {
			self.month = month
			self.day = day > 31 ? nil : day
		}
	}
	
	/**
	Initializes a date with our `DateAndTimeParser`.
	
	Will fail unless the string contains at least a valid year.
	
	- parameter string: The string to parse the date from
	*/
	public init?(string: String) {
		let parsed = DateAndTimeParser.sharedParser.parse(string)
		if nil == parsed.date {
			return nil
		}
		year = parsed.date!.year
		month = parsed.date!.month
		day = parsed.date!.day
	}
	
	/**
	- returns: Today's date
	*/
	public static func today() -> Date {
		let (date, _, _) = DateNSDateConverter.sharedConverter.parse(date: NSDate())
		return date
	}
	
	
	// MARK: Protocols
	
	public var nsDate: NSDate {
		return DateNSDateConverter.sharedConverter.create(self)
	}
	
	public var description: String {
		if let m = month {
			if let d = day {
				return String(format: "%04d-%02d-%02d", year, m, d)
			}
			return String(format: "%04d-%02d", year, m)
		}
		return String(format: "%04d", year)
	}
}

extension Date: Comparable {  }
public func <(lhs: Date, rhs: Date) -> Bool {
	if lhs.year == rhs.year {
		if lhs.month == rhs.month {
			return lhs.day < rhs.day
		}
		return lhs.month < rhs.month
	}
	return lhs.year < rhs.year
}

extension Date: Equatable {  }
public func ==(lhs: Date, rhs: Date) -> Bool {
	return lhs.year == rhs.year
		&& lhs.month == rhs.month
		&& lhs.day == rhs.day
}



/**
A time during the day, optionally with seconds, usually for human communication.

Minimum of 00:00 and maximum of < 24:00. There is no timezone. Since decimal precision has significance in FHIR, Time initialized from a
string will remember the seconds string until it is manually set.
*/
public struct Time: DateAndTime {
	
	/// The hour of the day; cannot be higher than 23.
	public var hour: UInt8 {
		didSet {
			if hour > 23 {
				hour = 23
			}
		}
	}
	
	/// The minute of the hour; cannot be larger than 59
	public var minute: UInt8 {
		didSet {
			if minute > 59 {
				minute = 59
			}
		}
	}
	
	/// The second of the minute; must be smaller than 60
	public var second: Double? {
		didSet {
			if second >= 60 {
				second = 59.999999999
			}
			tookSecondsFromString = nil
		}
	}
	
	/// If initialized from string, this was the string for the seconds; we use this to remember precision.
	public internal(set) var tookSecondsFromString: String?
	
	/**
	Dedicated initializer. Overflows seconds and minutes to arrive at the final time, which must be less than 24:00:00 or it will be capped.
	
	The `secondsFromString` parameter will be discarded if it is negative or higher than 60.
	
	- parameter hour:              Hour of day, cannot be greater than 23 (a time of 24:00 is illegal)
	- parameter minute:            Minutes of the hour; if greater than 59 will roll over into hours
	- parameter second:            Seconds of the minute; if 60 or more will roll over into minutes and discard `secondsFromString`
	- parameter secondsFromString: If time was initialized from a string, you can provide the seconds string here to ensure precision is
	                               kept. You are responsible to ensure that this string actually represents what's passed into `seconds`.
	*/
	public init(hour: UInt8, minute: UInt8, second: Double?, secondsFromString: String? = nil) {
		var overflowMinute: UInt = 0
		var overflowHour: UInt = 0
		
		if second >= 60.0 {
			self.second = second! % 60
			overflowMinute = UInt((second! - self.second!) / 60)
		}
		else {
			self.second = (second < 0.0) ? nil : second
			self.tookSecondsFromString = (second < 0.0) ? nil : secondsFromString
		}
		
		let mins = UInt(minute) + overflowMinute
		if mins > 59 {
			self.minute = UInt8(mins % 60)
			overflowHour = (mins - (mins % 60)) / 60
		}
		else {
			self.minute = UInt8(mins)
		}
		
		let hrs = UInt(hour) + overflowHour
		if hrs > 23 {
			self.hour = 23
			self.minute = 59
			self.second = 59.999999999
			self.tookSecondsFromString = nil
		}
		else {
			self.hour = UInt8(hrs)
		}
	}
	
	/**
	Initializes a time from a time string by passing it through `DateAndTimeParser`.
	
	Will fail unless the string contains at least hour and minute.
	*/
	public init?(string: String) {
		let parsed = DateAndTimeParser.sharedParser.parse(string, isTimeOnly: true)
		guard let time = parsed.time else {
			return nil
		}
		hour = time.hour
		minute = time.minute
		second = time.second
		tookSecondsFromString = time.tookSecondsFromString
	}
	
	/**
	- returns: The clock time of right now.
	*/
	public static func now() -> Time {
		let (_, time, _) = DateNSDateConverter.sharedConverter.parse(date: NSDate())
		return time
	}
	
	
	// MARK: Protocols
	
	public var nsDate: NSDate {
		return DateNSDateConverter.sharedConverter.create(self)
	}
	
	public var description: String {
		if let secStr = tookSecondsFromString {
			return String(format: "%02d:%02d:%@", hour, minute, secStr)
		}
		if let s = second {
			return String(format: "%02d:%02d:%@%g", hour, minute, (s < 10) ? "0" : "", s)
		}
		return String(format: "%02d:%02d", hour, minute)
	}
}

extension Time: Comparable {  }
public func <(lhs: Time, rhs: Time) -> Bool {
	if lhs.hour == rhs.hour {
		if lhs.minute == rhs.minute {
			return lhs.second < rhs.second
		}
		return lhs.minute < rhs.minute
	}
	return lhs.hour < rhs.hour
}

extension Time: Equatable {  }
public func ==(lhs: Time, rhs: Time) -> Bool {
	if nil != lhs.second && nil != rhs.second {
		return lhs.description == rhs.description		// must respect decimal precision of seconds, which `description` takes care of
	}
	return lhs.hour == rhs.hour
		&& lhs.minute == rhs.minute
		&& lhs.second == rhs.second
}


/**
A date, optionally with time, as used in human communication.

If a time is specified there must be a timezone; defaults to the system reported local timezone.
*/
public struct DateTime: DateAndTime {
	
	/// The date.
	public var date: Date
	
	/// The time.
	public var time: Time?
	
	/// The timezone
	public var timeZone: NSTimeZone? {
		didSet {
			timeZoneString = nil
		}
	}
	
	/// The timezone string seen during deserialization; to be used on serialization unless the timezone changed.
	var timeZoneString: String?
	
	/**
	This very date and time.
	
	- returns: A DateTime instance representing current date and time.
	*/
	public static func now() -> DateTime {
		return DateTime(date: Date.today(), time: Time.now(), timeZone: NSTimeZone(abbreviation: "UTC")!)
	}
	
	/**
	Designated initializer, takes a date and optionally a time and a timezone.
	
	If time is given but no timezone, the instance is assigned the local time zone.
	
	- parameter date:     The date of the date-time
	- parameter time:     The time of the date-time
	- parameter timeZone: The timezone
	*/
	public init(date: Date, time: Time?, timeZone: NSTimeZone?) {
		self.date = date
		self.time = time
		if nil != time && nil == timeZone {
			self.timeZone = NSTimeZone.localTimeZone()
		}
		else {
			self.timeZone = timeZone
		}
	}
	
	/**
	Uses `DateAndTimeParser` to initialize from a date-time string.
	
	If time is given but no timezone, the instance is assigned the local time zone.
	
	- parameter string: The string the date-time is parsed from
	*/
	public init?(string: String) {
		let (date, time, tz, tzString) = DateAndTimeParser.sharedParser.parse(string)
		if nil == date {
			return nil
		}
		self.date = date!
		if let time = time {
			self.time = time
			self.timeZone = nil == tz ? NSTimeZone.localTimeZone() : tz
			self.timeZoneString = tzString
		}
	}
	
	
	// MARK: Protocols
	
	public var nsDate: NSDate {
		if nil != time && nil != timeZone {
			return DateNSDateConverter.sharedConverter.create(date: date, time: time!, timeZone: timeZone!)
		}
		return DateNSDateConverter.sharedConverter.create(date)
	}
	
	public var description: String {
		if let tm = time {
			if let tz = timeZoneString ?? timeZone?.offset() {
				return String(format: "%@T%@%@", date.description, tm.description, tz)
			}
		}
		return date.description
	}
}

extension DateTime: Comparable {  }
public func <(lhs: DateTime, rhs: DateTime) -> Bool {
	let lhd = lhs.nsDate
	let rhd = rhs.nsDate
	return (lhd.compare(rhd) == .OrderedAscending)
}

extension DateTime: Equatable {  }
public func ==(lhs: DateTime, rhs: DateTime) -> Bool {
	let lhd = lhs.nsDate
	let rhd = rhs.nsDate
	return (lhd.compare(rhd) == .OrderedSame)
}


/**
An instant in time, known at least to the second and with a timezone, for machine times.
*/
public struct Instant: DateAndTime {
	
	/// The date.
	public var date: Date {
		didSet {
			if nil == date.month {
				date.month = 1
			}
			if nil == date.day {
				date.day = 1
			}
		}
	}
	
	/// The time, including seconds.
	public var time: Time {
		didSet {
			if nil == time.second {
				time.second = 0.0
			}
		}
	}
	
	/// The timezone.
	public var timeZone: NSTimeZone {
		didSet {
			timeZoneString = nil
		}
	}
	
	/// The timezone string seen during deserialization; to be used on serialization unless the timezone changed.
	var timeZoneString: String?
	
	/**
	This very instant.
	
	- returns: An Instant instance representing current date and time.
	*/
	public static func now() -> Instant {
		let (date, time, tz) = DateNSDateConverter.sharedConverter.parse(date: NSDate())
		return Instant(date: date, time: time, timeZone: tz)
	}
	
	/** Designated initializer.
	
	- parameter date:     The date of the instant; ensures to have month and day (which are optional in the `Date` construct)
	- parameter time:     The time of the instant; ensures to have seconds (which are optional in the `Time` construct)
	- parameter timeZone: The timezone
	*/
	public init(date: Date, time: Time, timeZone: NSTimeZone) {
		self.date = date
		if nil == self.date.month {
			self.date.month = 1
		}
		if nil == self.date.day {
			self.date.day = 1
		}
		self.time = time
		if nil == self.time.second {
			self.time.second = 0.0
		}
		self.timeZone = timeZone
	}
	
	/** Uses `DateAndTimeParser` to initialize from a date-time string.
	
	- parameter string: The string to parse the instant from
	*/
	public init?(string: String) {
		let (date, time, tz, tzString) = DateAndTimeParser.sharedParser.parse(string)
		if nil == date || nil == date!.month || nil == date!.day || nil == time || nil == time!.second || nil == tz {
			return nil
		}
		self.date = date!
		self.time = time!
		self.timeZone = tz!
		self.timeZoneString = tzString!
	}
	
	
	// MARK: Protocols
	
	public var nsDate: NSDate {
		return DateNSDateConverter.sharedConverter.create(date: date, time: time, timeZone: timeZone)
	}
	
	public var description: String {
		let tz = timeZoneString ?? timeZone.offset()
		return String(format: "%@T%@%@", date.description, time.description, tz)
	}
}

extension Instant: Comparable {  }
public func <(lhs: Instant, rhs: Instant) -> Bool {
	let lhd = lhs.nsDate
	let rhd = rhs.nsDate
	return (lhd.compare(rhd) == .OrderedAscending)
}

extension Instant: Equatable {  }
public func ==(lhs: Instant, rhs: Instant) -> Bool {
	let lhd = lhs.nsDate
	let rhd = rhs.nsDate
	return (lhd.compare(rhd) == .OrderedSame)
}

extension Instant {
	
	/**
	Attempts to parse an Instant from RFC1123-formatted date strings, usually used by HTTP headers:
	
	- "EEE',' dd MMM yyyy HH':'mm':'ss z"
	- "EEEE',' dd'-'MMM'-'yy HH':'mm':'ss z" (RFC850)
	- "EEE MMM d HH':'mm':'ss yyyy"
	
	Created by taking liberally from Marcus Rohrmoser's blogpost at http://blog.mro.name/2009/08/nsdateformatter-http-header/
	
	- parameter httpDate: The date string to parse
	- returns: An Instant if parsing was successful, nil otherwise
	*/
	public static func fromHttpDate(httpDate: String) -> Instant? {
		let formatter = NSDateFormatter()
		formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
		formatter.timeZone = NSTimeZone(abbreviation: "GMT")
		formatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss z"
		if let date = formatter.dateFromString(httpDate) {
			return date.fhir_asInstant()
		}
		
		formatter.dateFormat = "EEEE',' dd'-'MMM'-'yy HH':'mm':'ss z"
		if let date = formatter.dateFromString(httpDate) {
			return date.fhir_asInstant()
		}
		
		formatter.dateFormat = "EEE MMM d HH':'mm':'ss yyyy"
		if let date = formatter.dateFromString(httpDate) {
			return date.fhir_asInstant()
		}
		return nil
	}
}


/**
Converts between NSDate and our Date, Time, DateTime and Instance structs.
*/
class DateNSDateConverter {
	
	/// The singleton instance
	static var sharedConverter = DateNSDateConverter()
	
	let calendar: NSCalendar
	let utc: NSTimeZone
	
	init() {
		calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
		utc = NSTimeZone(abbreviation: "UTC")!
		calendar.timeZone = utc
	}
	
	
	// MARK: Parsing
	
	/**
	Execute parsing. Will use `calendar` to split the NSDate into components.
	
	- parameter date: The NSDate to parse into structs
	- returns: A tuple with (Date, Time, NSTimeZone)
	*/
	func parse(date inDate: NSDate) -> (Date, Time, NSTimeZone) {
		let flags: NSCalendarUnit = [.Year, .Month, .Day, .Hour, .Minute, .Second, .Nanosecond, .TimeZone]
		let comp = calendar.components(flags, fromDate: inDate)
		
		let date = Date(year: comp.year, month: UInt8(comp.month), day: UInt8(comp.day))
		let zone = comp.timeZone ?? utc
		let secs = Double(comp.second) + (Double(comp.nanosecond) / 1000000000)
		let time = Time(hour: UInt8(comp.hour), minute: UInt8(comp.minute), second: secs)
		
		return (date, time, zone)
	}
	
	
	// MARK: Creation
	
	func create(date: Date) -> NSDate {
		return _create(date: date, time: nil, timeZone: nil)
	}
	
	func create(time: Time) -> NSDate {
		return _create(date: nil, time: time, timeZone: nil)
	}
	
	func create(date date: Date, time: Time, timeZone: NSTimeZone) -> NSDate {
		return _create(date: date, time: time, timeZone: timeZone)
	}
	
	func _create(date date: Date?, time: Time?, timeZone: NSTimeZone?) -> NSDate {
		let comp = NSDateComponents()
		comp.timeZone = timeZone ?? utc
		
		if let yr = date?.year {
			comp.year = yr
		}
		if let mth = date?.month {
			comp.month = Int(mth)
		}
		if let d = date?.day {
			comp.day = Int(d)
		}
		
		if let hr = time?.hour {
			comp.hour = Int(hr)
		}
		if let min = time?.minute {
			comp.minute = Int(min)
		}
		if let sec = time?.second {
			comp.second = Int(floor(sec))
			comp.nanosecond = Int(sec % 1000000000)
		}
		
		return calendar.dateFromComponents(comp) ?? NSDate()
	}
}


/**
Parses Date and Time from strings in a narrow set of the extended ISO 8601 format.
*/
class DateAndTimeParser {
	
	/// The singleton instance
	static var sharedParser = DateAndTimeParser()
	
	/**
	Parses a date string in "YYYY[-MM[-DD]]" and a time string in "hh:mm[:ss[.sss]]" (extended ISO 8601) format,
	separated by "T" and followed by either "Z" or a valid time zone offset in the "±hh[:?mm]" format.
	
	Does not currently check if the day exists in the given month.
	
	- parameter string: The date string to parse
	- parameter isTimeOnly: If true assumes that the string describes time only
	- returns: A tuple with (Date?, Time?, NSTimeZone?, String? [for time zone])
	*/
	func parse(string: String, isTimeOnly: Bool=false) -> (date: Date?, time: Time?, tz: NSTimeZone?, tzString: String?) {
		let scanner = NSScanner(string: string)
		var date: Date?
		var time: Time?
		var tz: NSTimeZone?
		var tzString: String?
		
		// scan date (must have at least the year)
		if !isTimeOnly {
			var year = 0
			if scanner.scanInteger(&year) && year < 10000 {			// dates above 9999 are considered special cases
				var month = 0
				if scanner.scanString("-", intoString: nil) && scanner.scanInteger(&month) && month <= 12 {
					var day = 0
					if scanner.scanString("-", intoString: nil) && scanner.scanInteger(&day) && day <= 31 {
						date = Date(year: year, month: UInt8(month), day: UInt8(day))
					}
					else {
						date = Date(year: year, month: UInt8(month), day: nil)
					}
				}
				else {
					date = Date(year: year, month: nil, day: nil)
				}
			}
		}
		
		// scan time
		if isTimeOnly || scanner.scanString("T", intoString: nil) {
			var hour = 0
			var minute = 0
			if scanner.scanInteger(&hour) && hour >= 0 && hour < 24 && scanner.scanString(":", intoString: nil)
				&& scanner.scanInteger(&minute) && minute >= 0 && minute < 60 {
				
				let digitSet = NSCharacterSet.decimalDigitCharacterSet()
				let decimalSet = digitSet.mutableCopy() as! NSMutableCharacterSet
				decimalSet.addCharactersInString(".")
				
				var secStr: NSString?
				if scanner.scanString(":", intoString: nil) && scanner.scanCharactersFromSet(decimalSet, intoString: &secStr), let secStr = secStr as? String, let second = Double(secStr) where second < 60.0 {
					time = Time(hour: UInt8(hour), minute: UInt8(minute), second: second, secondsFromString: secStr)
				}
				else {
					time = Time(hour: UInt8(hour), minute: UInt8(minute), second: nil)
				}
				
				// scan zone
				if !scanner.atEnd {
					var negStr: NSString?
					if scanner.scanString("Z", intoString: nil) {
						tz = NSTimeZone(abbreviation: "UTC")
						tzString = "Z"
					}
					else if scanner.scanString("-", intoString: &negStr) || scanner.scanString("+", intoString: nil) {
						tzString = (nil == negStr) ? "+" : "-"
						var hourStr: NSString?
						if scanner.scanCharactersFromSet(digitSet, intoString: &hourStr) {
							tzString! += hourStr! as String
							var tzhour = 0
							var tzmin = 0
							if 2 == hourStr?.length {
								tzhour = hourStr!.integerValue
								if scanner.scanString(":", intoString: nil) && scanner.scanInteger(&tzmin) {
									tzString! += (tzmin < 10) ? ":0\(tzmin)" : ":\(tzmin)"
									if tzmin >= 60 {
										tzmin = 0
									}
								}
							}
							else if 4 == hourStr?.length {
								tzhour = Int(hourStr!.substringToIndex(2))!
								tzmin = Int(hourStr!.substringFromIndex(2))!
							}
							
							let offset = tzhour * 3600 + tzmin * 60
							tz = NSTimeZone(forSecondsFromGMT: nil == negStr ? offset : -1 * offset)
						}
					}
				}
			}
		}
		
		return (date, time, tz, tzString)
	}
}


/**
Extend NSDate to be able to return DateAndTime instances.
*/
public extension NSDate {
	
	/** Create a `Date` instance from the receiver. */
	func fhir_asDate() -> Date {
		let (date, _, _) = DateNSDateConverter.sharedConverter.parse(date: self)
		return date
	}
	
	/** Create a `Time` instance from the receiver. */
	func fhir_asTime() -> Time {
		let (_, time, _) = DateNSDateConverter.sharedConverter.parse(date: self)
		return time
	}
	
	/** Create a `DateTime` instance from the receiver. */
	func fhir_asDateTime() -> DateTime {
		let (date, time, tz) = DateNSDateConverter.sharedConverter.parse(date: self)
		return DateTime(date: date, time: time, timeZone: tz)
	}
	
	/** Create an `Instance` instance from the receiver. */
	func fhir_asInstant() -> Instant {
		let (date, time, tz) = DateNSDateConverter.sharedConverter.parse(date: self)
		return Instant(date: date, time: time, timeZone: tz)
	}
}


/**
Extend NSTimeZone to report the offset in "+00:00" or "Z" (for UTC/GMT) format.
*/
extension NSTimeZone {
	
	/**
	- returns: The offset as a string; uses "Z" if the timezone is UTC or GMT
	*/
	func offset() -> String {
		if "UTC" == abbreviation || "GMT" == abbreviation {
			return "Z"
		}
		
		let hr = abs((secondsFromGMT / 3600) - (secondsFromGMT % 3600))
		let min = abs((secondsFromGMT % 3600) / 60)
		
		return String(format: "%@%02d:%02d", secondsFromGMT >= 0 ? "+" : "-", hr, min)
	}
}

