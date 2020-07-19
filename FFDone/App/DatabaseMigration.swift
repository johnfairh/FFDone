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

        // Manually recreate transient field with junk to avoid disaster!
        dInstance.setValue("", forKey: #keyPath(Alarm.sectionOrder))

        // Create empty notes and set them up.  Core Data automatically takes
        // care of setting the reverse pointers, even at this level.
        let aNote = createNote(context: manager.destinationContext)
        dInstance.setValue(aNote, forKey: #keyPath(Alarm.activeNote))
        let dNote = createNote(context: manager.destinationContext)
        dInstance.setValue(dNote, forKey: #keyPath(Alarm.defaultNote))
    }

    private func createNote(context: NSManagedObjectContext) -> NSManagedObject {
        let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
        note.setValue("", forKey: #keyPath(Note.text))

        // confused.com - why am I forced to use NSDate here but a TimeInterval in main code??
        let now = Date()
        note.setValue(now, forKey: #keyPath(Note.cdCreationDate))
        note.setValue(Note.dateToDayStamp(date: now), forKey: #keyPath(Note.dayStamp))
        return note
    }
}

// MARK: - 8->9

// Version 9 adds full-fat epochs.  We hard-code the migration details here.

class EpochMigrationPolicy8to9: NSEntityMigrationPolicy {
    override func createRelationships(forDestination dInstance: NSManagedObject,
                                      in mapping: NSEntityMapping,
                                      manager: NSMigrationManager) throws {
        try super.createRelationships(forDestination: dInstance, in: mapping, manager: manager)

        let shortName: String
        let longName: String
        let majorVersion: Int64

        guard let epochId = dInstance.value(forKey: #keyPath(Epoch.sortOrder)) as? Int64 else {
            preconditionFailure("Missing epoch during migration: \(dInstance)")
        }
        switch epochId {
        case 1:
            shortName = "All"
            longName = "Final Fantasy XIV"
            majorVersion = 2
        case 2:
            shortName = "SHB"
            longName = "Shadowbringers"
            majorVersion = 5
        default:
            preconditionFailure("Bad epoch during migration: \(epochId)")
        }

        dInstance.setValue(shortName, forKey: #keyPath(Epoch.cdShortName))
        dInstance.setValue(longName, forKey: #keyPath(Epoch.cdLongName))
        dInstance.setValue(majorVersion, forKey: #keyPath(Epoch.majorVersion))
        dInstance.setValue(0, forKey: #keyPath(Epoch.minorVersion))
    }
}
