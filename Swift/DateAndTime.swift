//
//  DateAndTime.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 1/17/15.
//  2015, SMART Platforms.
//

import Foundation


/**
	A protocol for all our date and time structs.
 */
protocol DateAndTime: Printable
{
	var nsDate: NSDate { get set }
}


/**
	A date for use in human communication.

	Month and day are optional and there are no timezones.
 */
struct Date: DateAndTime
{
	/// The year.
	var year: Int
	
	/// The month of the year, maximum of 12.
	var month: UInt8? {
		didSet {
			if month > 12 {
				month = 12
			}
		}
	}
	
	/// The day of the month; must be valid for the month (not enforced in code!).
	var day: UInt8? {
		didSet {
			if day > 31 {
				day = 31
			}
		}
	}
	
	/** :returns: Today's date */
	static func today() -> Date {
		let (date, tz, time) = NSDateConverter.sharedConverter.parse(date: NSDate())
		return date
	}
	
	var nsDate: NSDate {
		get {
			return NSDateConverter.sharedConverter.create(self)
		}
		set {
			let (date, tz, time) = NSDateConverter.sharedConverter.parse(date: newValue)
			year = date.year
			month = date.month
			day = date.day
		}
	}
	
	var description: String {
		if let m = month {
			if let d = day {
				return String(format: "%04d-%02d-%02d", year, m, d)
			}
			return String(format: "%04d-%02d", year, m)
		}
		return String(format: "%04d", year)
	}
}

/**
	A time during the day, optionally with seconds, usually for human communication.

	Minimum of 00:00 and maximum of < 24:00, there is no timezone.
 */
struct Time: DateAndTime
{
	/// The hour of the day; cannot be higher than 23.
	var hour: UInt8 {
		didSet {
			if hour > 23 {
				hour = 23
			}
		}
	}
	
	/// The minute of the hour; cannot be larger than 59
	var minute: UInt8 {
		didSet {
			if minute > 59 {
				minute = 59
			}
		}
	}
	
	/// The second of the minute; must be smaller than 60
	var second: Double? {
		didSet {
			if second >= 60 {
				second = 59.999999999
			}
		}
	}
	
	init(hour: UInt8, minute: UInt8, second: Double?) {
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
	
	/** :returns: The time of right now. */
	static func now() -> Time {
		let (date, time, tz) = NSDateConverter.sharedConverter.parse(date: NSDate())
		return time
	}
	
	var nsDate: NSDate {
		get {
			return NSDateConverter.sharedConverter.create(self)
		}
		set {
			let (date, time, tz) = NSDateConverter.sharedConverter.parse(date: newValue)
			hour = time.hour
			minute = time.minute
			second = time.second
		}
	}
	
	var description: String {
		if let s = second {
			return String(format: "%02d:%02d:%@%g", hour, minute, (s < 10) ? "0" : "", s)
		}
		return String(format: "%02d:%02d", hour, minute)
	}
}


/**
	A date, optionally with time, as used in human communication.
	
	If a time is specified there must be a timezone; defaults to the system reported local timezone.
 */
struct DateTime: DateAndTime
{
	/// The date.
	var date: Date
	
	/// The time.
	var time: Time?
	
	/// The timezone
	var timeZone: NSTimeZone?
	
	init(date: Date, time: Time?, timeZone: NSTimeZone?) {
		self.date = date
		self.time = time
		if nil != time && nil == timeZone {
			self.timeZone = NSTimeZone.localTimeZone()
		}
		else {
			self.timeZone = timeZone
		}
	}
	
	var nsDate: NSDate {
		get {
			if nil != time && nil != timeZone {
				return NSDateConverter.sharedConverter.create(date: date, time: time!, timeZone: timeZone!)
			}
			return NSDateConverter.sharedConverter.create(date)
		}
		set {
			let (dt, tm, tz) = NSDateConverter.sharedConverter.parse(date: newValue)
			date = dt
			time = tm
			timeZone = tz
		}
	}
	
	var description: String {
		if let tm = time {
			if let tz = timeZone {
				return String(format: "%@T%@%@", date.description, tm.description, tz.offset())
			}
		}
		return date.description
	}
}


/**
	An instant in time, known at least to the second and with a timezone, for machine times.
 */
struct Instant: DateAndTime
{
	/// The date.
	var date: Date
	
	/// The time, including seconds.
	var time: Time {
		didSet {
			if nil == time.second {
				time.second = 0
			}
		}
	}
	
	/// The timezone.
	var timeZone: NSTimeZone
	
	/** :returns: The current date and time. */
	static func now() -> Instant {
		let (date, time, tz) = NSDateConverter.sharedConverter.parse(date: NSDate())
		return Instant(date: date, time: time, timeZone: tz)
	}
	
	var nsDate: NSDate {
		get {
			return NSDateConverter.sharedConverter.create(date: date, time: time, timeZone: timeZone)
		}
		set {
			(date, time, timeZone) = NSDateConverter.sharedConverter.parse(date: newValue)
		}
	}
	
	var description: String {
		return String(format: "%@T%@%@", date.description, time.description, timeZone.offset())
	}
}


class NSDateConverter
{
	/// The singleton instance
	class var sharedConverter: NSDateConverter {
		struct Static {
			static let instance = NSDateConverter()
		}
		return Static.instance
	}
	
	let calendar: NSCalendar
	let gmt: NSTimeZone
	
	init() {
		calendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)!
		gmt = NSTimeZone(abbreviation: "GMT")!
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
		let zone = comp.timeZone ?? gmt
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
		comp.timeZone = timeZone ?? gmt
		
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
	Extend NSTimeZone to report the offset in "+00:00" format.
 */
extension NSTimeZone
{
	func offset() -> String {
		let hr = abs((secondsFromGMT / 3600) - (secondsFromGMT % 3600))
		let min = abs((secondsFromGMT % 3600) / 60)
		
		return String(format: "%@%02d:%02d", secondsFromGMT >= 0 ? "+" : "-", hr, min)
	}
}

