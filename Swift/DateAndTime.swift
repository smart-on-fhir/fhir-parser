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
protocol DateAndTime: Printable, Comparable
{
	var nsDate: NSDate { get set }
}


/**
	A date for use in human communication.

	Month and day are optional and there are no timezones.
 */
public struct Date: DateAndTime
{
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
	
	public init(year: Int, month: UInt8?, day: UInt8?) {
		self.year = year
		self.month = month > 12 ? nil : month
		self.day = day > 31 ? nil : day
	}
	
	/**
		Initializes a date with our `DateAndTimeParser`.
	
		Will fail unless the string contains at least a valid year.
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
	
	/** :returns: Today's date */
	public static func today() -> Date {
		let (date, tz, time) = DateNSDateConverter.sharedConverter.parse(date: NSDate())
		return date
	}
	
	
	// MARK: Protocols
	
	public var nsDate: NSDate {
		get {
			return DateNSDateConverter.sharedConverter.create(self)
		}
		set {
			let (date, tz, time) = DateNSDateConverter.sharedConverter.parse(date: newValue)
			year = date.year
			month = date.month
			day = date.day
		}
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

public func <(lhs: Date, rhs: Date) -> Bool {
	if lhs.year == rhs.year {
		if lhs.month == rhs.month {
			return lhs.day < rhs.day
		}
		return lhs.month < rhs.month
	}
	return lhs.year < rhs.year
}

public func ==(lhs: Date, rhs: Date) -> Bool {
	return lhs.year == rhs.year
		&& lhs.month == rhs.month
		&& lhs.day == rhs.day
}



/**
	A time during the day, optionally with seconds, usually for human communication.

	Minimum of 00:00 and maximum of < 24:00, there is no timezone.
 */
public struct Time: DateAndTime
{
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
		}
	}
	
	/** Dedicated initializer. Overflows seconds and minutes to arrive at the final time, which must be less than
		24:00:00 or it will be capped.
	 */
	public init(hour: UInt8, minute: UInt8, second: Double?) {
		var overflowMinute: Int = 0
		var overflowHour: Int = 0
		
		if second >= 60.0 {
			self.second = second! % 60
			overflowMinute = Int((second! - self.second!) / 60)
		}
		else {
			self.second = second
		}
		
		let mins = Int(minute) + overflowMinute
		if mins > 59 {
			self.minute = UInt8(mins % 60)
			overflowHour = (mins - (mins % 60)) / 60
		}
		else {
			self.minute = minute + overflowMinute
		}
		
		let hrs = Int(hour) + overflowHour
		if hrs > 23 {
			self.hour = 23
			self.minute = 59
			self.second = 59.999999999
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
		if nil == parsed.time {
			return nil
		}
		hour = parsed.time!.hour
		minute = parsed.time!.minute
		second = parsed.time!.second
	}
	
	/** :returns: The clock time of right now. */
	public static func now() -> Time {
		let (date, time, tz) = DateNSDateConverter.sharedConverter.parse(date: NSDate())
		return time
	}
	
	
	// MARK: Protocols
	
	public var nsDate: NSDate {
		get {
			return DateNSDateConverter.sharedConverter.create(self)
		}
		set {
			let (date, time, tz) = DateNSDateConverter.sharedConverter.parse(date: newValue)
			hour = time.hour
			minute = time.minute
			second = time.second
		}
	}
	
	public var description: String {
		if let s = second {
			return String(format: "%02d:%02d:%@%g", hour, minute, (s < 10) ? "0" : "", s)
		}
		return String(format: "%02d:%02d", hour, minute)
	}
}

public func <(lhs: Time, rhs: Time) -> Bool {
	if lhs.hour == rhs.hour {
		if lhs.minute == rhs.minute {
			return lhs.second < rhs.second
		}
		return lhs.minute < rhs.minute
	}
	return lhs.hour < rhs.hour
}

public func ==(lhs: Time, rhs: Time) -> Bool {
	return lhs.hour == rhs.hour
		&& lhs.minute == rhs.minute
		&& lhs.second == rhs.second
}


/**
	A date, optionally with time, as used in human communication.
	
	If a time is specified there must be a timezone; defaults to the system reported local timezone.
 */
public struct DateTime: DateAndTime
{
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
		Designated initializer, takes a date and optionally a time and a timezone.
	
		If time is given but no timezone, the instance is assigned the local time zone.
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
	 */
	public init?(string: String) {
		let (date, time, tz, tzString) = DateAndTimeParser.sharedParser.parse(string)
		if nil == date {
			return nil
		}
		self.date = date!
		if nil != time {
			self.time = time
			self.timeZone = nil == tz ? NSTimeZone.localTimeZone() : tz
			self.timeZoneString = tzString
		}
	}
	
	
	// MARK: Protocols
	
	public var nsDate: NSDate {
		get {
			if nil != time && nil != timeZone {
				return DateNSDateConverter.sharedConverter.create(date: date, time: time!, timeZone: timeZone!)
			}
			return DateNSDateConverter.sharedConverter.create(date)
		}
		set {
			let (dt, tm, tz) = DateNSDateConverter.sharedConverter.parse(date: newValue)
			date = dt
			time = tm
			timeZone = tz
		}
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

public func <(lhs: DateTime, rhs: DateTime) -> Bool {
	let lhd = lhs.nsDate
	let rhd = rhs.nsDate
	return (lhd.compare(rhd) == .OrderedAscending)
}

public func ==(lhs: DateTime, rhs: DateTime) -> Bool {
	let lhd = lhs.nsDate
	let rhd = rhs.nsDate
	return (lhd.compare(rhd) == .OrderedSame)
}


/**
	An instant in time, known at least to the second and with a timezone, for machine times.
 */
public struct Instant: DateAndTime
{
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
	
	/** :returns: The current date and time. */
	public static func now() -> Instant {
		let (date, time, tz) = DateNSDateConverter.sharedConverter.parse(date: NSDate())
		return Instant(date: date, time: time, timeZone: tz)
	}
	
	/** Designated initializer. */
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
	
	/** Uses `DateAndTimeParser` to initialize from a date-time string. */
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
		get {
			return DateNSDateConverter.sharedConverter.create(date: date, time: time, timeZone: timeZone)
		}
		set {
			(date, time, timeZone) = DateNSDateConverter.sharedConverter.parse(date: newValue)
		}
	}
	
	public var description: String {
		let tz = timeZoneString ?? timeZone.offset()
		return String(format: "%@T%@%@", date.description, time.description, tz)
	}
}

public func <(lhs: Instant, rhs: Instant) -> Bool {
	let lhd = lhs.nsDate
	let rhd = rhs.nsDate
	return (lhd.compare(rhd) == .OrderedAscending)
}

public func ==(lhs: Instant, rhs: Instant) -> Bool {
	let lhd = lhs.nsDate
	let rhd = rhs.nsDate
	return (lhd.compare(rhd) == .OrderedSame)
}


/**
	Converts between NSDate and our Date, Time, DateTime and Instance structs.
 */
class DateNSDateConverter
{
	/// The singleton instance
	class var sharedConverter: DateNSDateConverter {
		struct Static {
			static let instance = DateNSDateConverter()
		}
		return Static.instance
	}
	
	let calendar: NSCalendar
	let utc: NSTimeZone
	
	init() {
		calendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)!
		utc = NSTimeZone(abbreviation: "UTC")!
	}
	
	
	// MARK: Parsing
	
	func parse(date inDate: NSDate) -> (Date, Time, NSTimeZone) {
		let comp = calendar.components(
			.CalendarUnitYear
				| .CalendarUnitMonth
				| .CalendarUnitDay
				| .CalendarUnitHour
				| .CalendarUnitMinute
				| .CalendarUnitSecond
				| .CalendarUnitNanosecond
				| .CalendarUnitTimeZone, fromDate: inDate)
		
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
	
	func create(#date: Date, time: Time, timeZone: NSTimeZone) -> NSDate {
		return _create(date: date, time: time, timeZone: timeZone)
	}
	
	func _create(#date: Date?, time: Time?, timeZone: NSTimeZone?) -> NSDate {
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
class DateAndTimeParser
{
	/// The singleton instance
	class var sharedParser: DateAndTimeParser {
		struct Static {
			static let instance = DateAndTimeParser()
		}
		return Static.instance
	}
	
	/**
		Parses a date string in "YYYY[-MM[-DD]]" and a time string in "hh:mm[:ss[.sss]]" (extended ISO 8601) format,
		separated by "T" and followed by either "Z" or a valid time zone offset in the "±hh[:?mm]" format.
	
		Does not currently check if the day exists in the given month.
	
		:param: string The date string to parse
		:param: isTimeOnly If true assumes that the string describes time only
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
			if scanner.scanInteger(&hour) && hour < 24 && scanner.scanString(":", intoString: nil)
				&& scanner.scanInteger(&minute) && minute < 60 {
				var second = 0.0
				if scanner.scanString(":", intoString: nil) && scanner.scanDouble(&second) && second >= 0.0 && second < 60.0 {
					time = Time(hour: UInt8(hour), minute: UInt8(minute), second: second)
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
						if scanner.scanCharactersFromSet(NSCharacterSet.decimalDigitCharacterSet(), intoString: &hourStr) {
							tzString! += hourStr!
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
								tzhour = hourStr!.substringToIndex(2).toInt()!
								tzmin = hourStr!.substringFromIndex(2).toInt()!
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
	Extend NSTimeZone to report the offset in "+00:00" or "Z" (for UTC/GMT) format.
 */
extension NSTimeZone
{
	func offset() -> String {
		if "UTC" == abbreviation || "GMT" == abbreviation {
			return "Z"
		}
		
		let hr = abs((secondsFromGMT / 3600) - (secondsFromGMT % 3600))
		let min = abs((secondsFromGMT % 3600) / 60)
		
		return String(format: "%@%02d:%02d", secondsFromGMT >= 0 ? "+" : "-", hr, min)
	}
}

