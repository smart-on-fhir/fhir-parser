//
//  FHIRTypes.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 12/16/14.
//  2014, SMART Health IT.
//

import Foundation
import RealmSwift

/**
A JSON dictionary, with `String` keys and `AnyObject` values.
*/
public typealias FHIRJSON = [String: Any]


/**
Data encoded as a base-64 string.
*/
final public class Base64Binary: Object, ExpressibleByStringLiteral, Comparable {
	public typealias UnicodeScalarLiteralType = Character
	public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
	
	public dynamic var value: String?
	
	public convenience init(val: String) {
        self.init()
		self.value = val
	}
	
    public convenience init(string val: String) {
        self.init()
        self.value = val
    }
    
	// MARK: - ExpressibleByStringLiteral
	
	public convenience init(stringLiteral value: StringLiteralType) {
        self.init()
		self.value = value
	}
	
	public convenience init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.init()
		self.value = "\(value)"
	}
	
	public convenience init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.init()
		self.value = value
	}
	
	
	// MARK: - Printable, Equatable and Comparable
	
	override public var description: String {
		return "<Base64Binary; \(nil != value ? value!.characters.count : 0) chars>"
	}
	
	public static func <(lh: Base64Binary, rh: Base64Binary) -> Bool {
		guard let lhs = lh.value else {
			return true
		}
		guard let rhs = rh.value else {
			return false
		}
		return lhs < rhs
	}
	
	public static func ==(lhs: Base64Binary, rhs: Base64Binary) -> Bool {
		return lhs.value == rhs.value
	}
    
    public static func ==(lhs: Base64Binary?, rhs: Base64Binary) -> Bool {
        if let lhs = lhs {
            return lhs == rhs
        }
        
        return false
    }
    
    public static func ==(lhs: Base64Binary, rhs: Base64Binary?) -> Bool {
        if let rhs = rhs {
            return lhs == rhs
        }
        
        return false
    }
}

// MARK: - Helper Functions

extension String {
	/**
	Convenience getter using `NSLocalizedString()` with no comment.
	
	TODO: On Linux this currently simply returns self
	*/
	public var fhir_localized: String {
		#if os(Linux)
		return self
		#else
		return NSLocalizedString(self, comment: "")
		#endif
	}
}

/**
Execute a `print()`, prepending filename, line and function/method name, if `DEBUG` is defined.
*/
public func fhir_logIfDebug(_ message: @autoclosure () -> String, function: String = #function, file: String = #file, line: Int = #line) {
#if DEBUG
	print("SwiftFHIR [\(URL(fileURLWithPath: file).lastPathComponent):\(line)] \(function)  \(message())")
#endif
}

/**
Execute a `print()`, prepending filename, line and function/method name and "WARNING" prepended.
*/
public func fhir_warn(_ message: @autoclosure () -> String, function: String = #function, file: String = #file, line: Int = #line) {
	print("SwiftFHIR [\(URL(fileURLWithPath: file).lastPathComponent):\(line)] \(function)  WARNING: \(message())")
}

