//
//  DatabaseMigration.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import Foundation
import CoreData

/// Full-fat database migrations.

// MARK: - 4->5

// Version 5 adds note objects to alarms.  To make the app code easier we create empty
// note objects for each existing alarm.
//
// This is particularly entertaining because our Model framework is not available and
// so we have to do it with raw core data.

class AlarmMigrationPolicy4to5: NSEntityMigrationPolicy {
    override func createRelationships(forDestination dInstance: NSManagedObject,
                                      in mapping: NSEntityMapping,
                                      manager: NSMigrationManager) throws {
        try super.createRelationships(forDestination: dInstance, in: mapping, manager: manager)
        print( "*** AlarmMigrationPolicy4to5 ***")
    }
}
