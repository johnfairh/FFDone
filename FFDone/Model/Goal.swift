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
    /// How many steps make up the goal.
    var totalSteps: Int {
        get {
            return Int(cdTotalSteps)
        }
        set {
            Log.assert(newValue > 0)
            mayComplete { self.cdTotalSteps = Int32(newValue) }
        }
    }

    /// We treat goals with just one step slightly differently in the UI.
    var hasSteps: Bool {
        return totalSteps > 1
    }

    /// How many steps of the goal have been done.
    var currentSteps: Int {
        get {
            return Int(cdCurrentSteps)
        }
        set {
            Log.assert(newValue >= 0)
            mayComplete { self.cdCurrentSteps = Int32(newValue) }
        }
    }

    /// How many steps left to complete? >= 0
    var stepsToGo: Int {
        return totalSteps - currentSteps
    }

    /// Are all the steps of the goal done?
    var isComplete: Bool {
        return totalSteps == currentSteps
    }

    /// Helper to wrap up a transition that may complete the goal.
    private func mayComplete(call: () -> Void) {
        let wasComplete = isComplete
        call()
        if !wasComplete && isComplete {
            completed()
        }
    }

    /// Perform processing when the goal gets completed.
    private func completed() {
        completionDate = Date()
    }
}
