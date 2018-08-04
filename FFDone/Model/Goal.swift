//
//  Goal.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Because Core Data is a special flower we need to have some weird stuff.
///
/// To do the section sorting we need a dedicated 'section' field.  We can't
/// use the section titles because CD insists on alphabetically sorting them.
///
/// So we have a `sectionOrder` String field that is updated whenever the `fav`
/// and `complete` states change.
enum GoalSection: String {
    case fav = "0"
    case active = "1"
    case complete = "2"

    static var titleMap: [String : String] =
        ["0" : "Favourites",
         "1" : "Active",
         "2" : "Complete"]
}

extension Goal {
    fileprivate func updateSectionOrder() {
        let section: GoalSection

        switch (isComplete, isFav) {
        case (false, true):  section = .fav
        case (false, false): section = .active
        case (true, _):      section = .complete
        }
        sectionOrder = section.rawValue
    }
}

extension Goal: ModelObject {
    /// Framework default sort order for find/query
    public static let defaultSortDescriptor = NSSortDescriptor(key: #keyPath(sortOrder), ascending: true)

    /// Allow for user reordering
    static let primarySortOrder = ModelSortOrder(keyName: #keyPath(sortOrder), ascending: false)

    /// Magic value for completion date for incomplete goals - need this for consistent sorting
    static let incompleteDate = Date(timeIntervalSinceReferenceDate: 0)

    static func createWithDefaults(model: Model) -> Goal {
        let goal = Goal.create(from: model)
        goal.name = ""
        goal.isFav = false
        goal.totalSteps = 1
        goal.sortOrder = Goal.getNextSortOrderValue(primarySortOrder, from: model)
        goal.creationDate = Date()
        goal.completionDate = Goal.incompleteDate
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
        let nowComplete = isComplete
        if !wasComplete && nowComplete {
            completed()
        } else if wasComplete && !nowComplete {
            uncompleted()
        }
    }

    /// Perform processing when the goal gets completed.
    private func completed() {
        completionDate = Date()
        updateSectionOrder()
    }

    /// Perform processing when the goal gets uncompleted.
    private func uncompleted() {
        completionDate = Goal.incompleteDate
        updateSectionOrder()
    }
}

// MARK: - Fav

extension Goal {
    /// Wrap this to allow updating the section ID
    var isFav: Bool {
        get {
            return cdIsFav
        }
        set {
            cdIsFav = newValue
            updateSectionOrder()
        }
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

    var debugText: String {
        return "[so=\(sortOrder) cdCompl=\(cdCompletionDate)]"
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

// MARK: - Queries

extension Goal {

    /// For the main goals view
    static func allSortedResultsSet(model: Model) -> ModelResultsSet {
        return sectionatedResultsSet(model: model, predicate: nil)
    }

    /// For searching in the goals view
    static func matchingSortedResultsSet(model: Model, string: String) -> ModelResultsSet {
        let predicate = NSPredicate(format: "\(#keyPath(name)) CONTAINS[cd] \"\(string)\"")
        return sectionatedResultsSet(model: model, predicate: predicate)
    }

    /// Carefully sorted order to drive main table
    private static func sectionatedResultsSet(model: Model, predicate: NSPredicate?) -> ModelResultsSet {
        // Fav -> Incomplete -> Complete
        let sectionsOrder = NSSortDescriptor(key: #keyPath(sectionOrder), ascending: true)

        // Completed more recently before older ones.
        // Should affect only completed goals.
        let completionOrder = NSSortDescriptor(key: #keyPath(cdCompletionDate), ascending: false)

        // Finally user sort order, mostly affect incomplete goals, newer before older.
        let userSortOrder = NSSortDescriptor(key: #keyPath(sortOrder), ascending: false)

        return createFetchedResults(model: model,
                                    predicate: predicate,
                                    sortedBy: [sectionsOrder, completionOrder, userSortOrder],
                                    sectionNameKeyPath: #keyPath(sectionOrder)).asModelResultsSet
    }

}
