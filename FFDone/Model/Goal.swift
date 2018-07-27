//
//  Goal.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

final class Goal : NSManagedObject, ModelObject {

    static let defaultSortDescriptor = NSSortDescriptor(key: "sortOrder", ascending: true)
    static let primarySortOrder = ModelSortOrder(keyName: "sortOrder")

    static func createWithDefaults(model: Model) -> Goal {
        let goal = Goal.create(from: model)
        goal.totalSteps = 1
        goal.sortOrder = Goal.getNextSortOrderValue(primarySortOrder, from: model)
        goal.creationDate = Date()
        return goal
    }
}

// MARK: - Timestamp wrapper utilities, allow `Date` in code and convert to TIs

extension Goal {
    var creationDate: Date {
        get {
            return Date(timeIntervalSinceReferenceDate: cdCreationDate)
        }
        set {
            cdCreationDate = newValue.timeIntervalSinceReferenceDate
        }
    }

    var completionDate: Date {
        get {
            return Date(timeIntervalSinceReferenceDate: cdCompletionDate)
        }
        set {
            cdCompletionDate = newValue.timeIntervalSinceReferenceDate
        }
    }
}

// MARK: - Steps and completion

extension Goal {
    var currentSteps: Int {
        get {
            return Int(cdCurrentSteps)
        }
        set {
            Log.assert(newValue >= 0)
            mayComplete { self.cdCurrentSteps = Int32(newValue) }
        }
    }

    var totalSteps: Int {
        get {
            return Int(cdTotalSteps)
        }
        set {
            Log.assert(newValue > 0)
            mayComplete { self.cdTotalSteps = Int32(newValue) }
        }
    }

    var isComplete: Bool {
        return totalSteps == currentSteps
    }

    func mayComplete(call: () -> Void) {
        let wasComplete = isComplete
        call()
        if !wasComplete && isComplete {
            completed()
        }
    }

    func completed() {
        completionDate = Date()
    }
}
