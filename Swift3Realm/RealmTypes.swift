//
//  RealmTypes.swift
//  SwiftFHIR
//
//  Created by Ryan Baldwin on 01/21/17
//  2017, Ryan Baldwin
//

import Foundation
import RealmSwift

public class RealmString: Object {
    public dynamic var value: String = ""

    public convenience init(val: String) {
        self.init()
        self.value = val
    }
}

public class RealmInt: Object {
    public dynamic var value: Int = 0

    public convenience init(val: Int) {
        self.init()
        self.value = val
    }
}

public class RealmDecimal: Object {
    private dynamic var _value = "0"

    public var value: Decimal {
        get { return Decimal(string: _value)! }
        set { _value = String(describing: newValue) }
    }

    public convenience init(string val: String) {
        self.init()
        self._value = val
    }

    public override class func ignoredProperties() -> [String] {
        return ["value"]
    }

    public static func ==(lhs: RealmDecimal, rhs: RealmDecimal) -> Bool {
        return lhs.value.isEqual(to: rhs.value)
    }
    
    public static func ==(lhs: RealmDecimal?, rhs: RealmDecimal) -> Bool {
        if let lhs = lhs {
            return lhs == rhs
        }
        
        return false
    }
    
    public static func ==(lhs: RealmDecimal, rhs: RealmDecimal?) -> Bool {
        if let rhs = rhs {
            return lhs == rhs
        }
        
        return false
    }    
}

public class RealmURL: Object {
    private dynamic var _value: String?
    
    private var _url: URL? = nil
    public var value: URL? {
        get {
            if _url == nil {
                _url = URL(string: _value ?? "")
            }
            
            return _url
        }
        set {
            _url = newValue
            _value = newValue?.absoluteString ?? ""
        }
    }
    
    public override class func ignoredProperties() -> [String] {
        return ["value", "_url"]
    }
}

/// Realm is limited in its polymorphism and can't contain a List of different
/// classes. As a result, for example, deserializing from JSON into a DomainResource
/// will fail if that resource has any contained resources.
///
/// In normal SwiftFHIR the `DomainResource.contained` works fine, but because of 
/// Swift's limitations it fails. `DomainResource.contained: RealmSwift<Resource>` 
/// will blow up at runtime. The workaround is to create a `ContainedResource: Resource`
/// Which will store the same information as `Resource`, but will also provide functionality
/// to store the original JSON and inflate it on demand into the proper type.
public class ContainedResource: Resource {
    public dynamic var resourceType: String?
    
    private dynamic var json: Data?
    
    private var _resource: FHIRAbstractBase? = nil
    public var resource: FHIRAbstractBase? {
        guard let resourceType = resourceType,
              let json = json else {
            return nil
        }
        
        if _resource == nil {
            let js = NSKeyedUnarchiver.unarchiveObject(with: json) as! FHIRJSON
            _resource = FHIRAbstractBase.factory(resourceType, json: js, owner: nil)
        }
        
        return _resource
    }
    
    public override func populate(from json: FHIRJSON?, presentKeys: inout Set<String>) -> [FHIRJSONError]? {
        var errors = super.populate(from: json, presentKeys: &presentKeys) ?? [FHIRJSONError]()        
        if let js = json {
            if let exist = js["resourceType"] {
                presentKeys.insert("resourceType")
                if let val = exist as? String {
                    self.resourceType = val
                }
                else {
                    errors.append(FHIRJSONError(key: "resourceType", wants: String.self, has: type(of: exist)))
                }
            }
            
            self.json = NSKeyedArchiver.archivedData(withRootObject: js)
        }
        
        return errors.isEmpty ? nil : errors
    }
    
    public override func asJSON() -> FHIRJSON {
        guard let resource = resource else {
            return ["fhir_comments": "Failed to serialize ContainedResource (\(self.resourceType)) because the resource was not set."]
        }
        
        return resource.asJSON()
    }
}
