//
//  Goal.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

extension Goal: ModelObject {
    /// This is used by the framework in some way I don't really remember
    public static let defaultSortDescriptor = NSSortDescriptor(key: "sortOrder", ascending: true)

    /// Allow for user reordering
    static let primarySortOrder = ModelSortOrder(keyName: "sortOrder")

    static func createWithDefaults(model: Model) -> Goal {
        let goal = Goal.create(from: model)
        goal.name = ""
        goal.totalSteps = 1
        goal.sortOrder = Goal.getNextSortOrderValue(primarySortOrder, from: model)
        goal.creationDate = Date()
        goal.completionDate = .distantPast
        goal.icon = Icon.getGoalDefault(model: model)
        return goal
    }
}

// MARK: - Timestamp wrapper utilities, allow `Date` in code and convert to TIs

extension Goal {
    /// Timestamp the goal was created
    var creationDate: Date {
        get {
            return Date(timeIntervalSinceReferenceDate: cdCreationDate)
        }
        set {
            cdCreationDate = newValue.timeIntervalSinceReferenceDate
        }
    }

    /// Timestamp the goal was [last] completed
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

// MARK: - View text helpers

extension Goal {

    private var stepsStatusText: String {
        return "\(currentSteps) out of \(totalSteps)"
    }

    private var completionTimeText: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: completionDate)
    }

    var progressText: String {
        if isComplete {
            return "Completed \(completionTimeText)"
        } else if currentSteps == 0 {
            return "Unstarted"
        } else {
            return stepsStatusText
        }
    }
}

// MARK: - View icon helpers

extension Goal {

    /// Image for general use representing the goal & its status, including badges
    var badgedImage: UIImage {
        let badgeText: String?
        if hasSteps && !isComplete {
            badgeText = String(stepsToGo)
        } else {
            badgeText = nil
        }

        return icon!.getStandardImage(withBadge: badgeText)
    }

    /// Just the image, no annotations, may need scaling
    var nativeImage: UIImage {
        return icon!.nativeImage
    }
}
