//
//  File.swift
//  realm-swift-fhir
//
//  Created by Ryan Baldwin on 2017-01-25.
//

import XCTest
import RealmSwift

/// Provides a small set of functionality to assist in Unit Testing something which depends on an in-memory Realm.
protocol RealmPersistenceTesting: class {}

extension RealmPersistenceTesting where Self: XCTestCase {
    /// Clears the current in-memory realm of all entities.
    func clear(realm: Realm) {
        try! realm.write {
            realm.deleteAll()
        }
    }
    
    /// Creates a new Realm based on the current configuration
    ///
    /// - Returns: A new Realm instance
    func makeRealm() -> Realm {
        var realm: Realm!
        stopwatch(label: "Time to fire up realm") {
            realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "RealmSwiftFHIRInMemDB"))
        }
        
        clear(realm: realm)
        return realm
    }

    func stopwatch(label: String, _ closure: () -> ()) {
        let start = Date()
        closure()
        let end = Date()
        let timeInterval: Double = end.timeIntervalSince(start)
        print("\(label): \(timeInterval)")
    }
}
