//
//  Goal.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

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

    /// Create an independent goal that mimicks this one
    func dup(model: Model) -> Goal {
        let goal = Goal.createWithDefaults(model: model)
        goal.name = name
        goal.icon = icon
        goal.isFav = isFav
        goal.totalSteps = totalSteps
        goal.tag = tag

        // NSFetchedResultsController throws very odd errors if it is run on
        // a nested model with unsaved records.  This workaround creates a further
        // child model, creates the notes in there, then saves the child model which
        // merges back into the current model -- while leaving the goal itself unsaved,
        // which is vital for save/cancel to work properly.
        if let myNotes = notes as? Set<Note> {
            let subModel = model.createChildModel()
            let subModelGoal = goal.convert(subModel)
            let newNotes = myNotes.sorted(by: { $0.cdCreationDate < $1.cdCreationDate }).map { $0.dup(model: subModel) }
            var now = Date()
            newNotes.forEach {
                $0.creationDate = now
                now.addTimeInterval(1) // keep the same order
                $0.goal = subModelGoal
            }
            subModel.save()
        }

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

    var stepsStatusText: String {
        return "\(currentSteps) out of \(totalSteps)"
    }

    private func getFormattedDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: date)
    }

    private var creationTimeText: String {
        return getFormattedDate(date: creationDate)
    }

    private var completionTimeText: String {
        return getFormattedDate(date: completionDate)
    }

    private var durationTimeText: String {
        let dateIntervalFormatter = DateIntervalFormatter()
        dateIntervalFormatter.dateStyle = .medium
        dateIntervalFormatter.timeStyle = .none
        return dateIntervalFormatter.string(from: creationDate, to: completionDate)
    }

    var debugText: String {
        return "[so=\(sortOrder) cdCompl=\(cdCompletionDate)]"
    }

    /// For table view
    var shortProgressText: String {
        if isComplete {
            return "Completed \(completionTimeText)"
        } else if currentSteps == 0 {
            return "Unstarted"
        } else {
            return stepsStatusText
        }
    }

    /// For view
    var longProgressText: String {
        if isComplete {
            return durationTimeText
        } else {
            return "Created \(creationTimeText)"
        }
    }
}

// MARK: - View icon helpers

extension Goal {

    private var imageAnnotationText: String? {
        guard hasSteps && !isComplete else {
            return nil
        }
        return String(stepsToGo)
    }

    /// Image for table use representing the goal & its status, including badges
    var badgedImage: UIImage {
        return icon!.getStandardImage(withBadge: imageAnnotationText)
    }

    /// Just the image, no annotations, may need scaling
    var nativeImage: UIImage {
        return icon!.nativeImage
    }

    /// Image with annotation at some size
    func getBadgedImage(size: CGSize) -> UIImage {
        return icon!.getBadgedImage(size: size, badge: imageAnnotationText)
    }
}

// MARK: - Sections

/// Because Core Data is a special flower we need to have some weird stuff.
///
/// To do the section sorting we need a dedicated 'section' field.  We can't
/// use the section titles because CD insists on alphabetically sorting them.
///
/// So we have a `sectionOrder` String field that is updated whenever the `fav`
/// and `complete` states change.
extension Goal {

    /// Section type, raw string used as core data primary index/section name.
    enum Section: String {
        case fav = "0"
        case active = "1"
        case complete = "2"

        static var titleMap: [String : String] =
            ["0" : "Favourites",
             "1" : "Active",
             "2" : "Complete"]
    }

    var section: Goal.Section {
        switch (isComplete, isFav) {
        case (false, true):  return .fav
        case (false, false): return .active
        case (true, _):      return .complete
        }
    }

    fileprivate func updateSectionOrder() {
        sectionOrder = section.rawValue
    }

    /// Handle the user modifying the section of a goal, update internal
    /// state to meet their desired one.  Sort order taken care of elsewhere.
    func userMove(newSection: Goal.Section) {
        let currentSection = section
        guard currentSection != newSection else {
            return
        }

        switch (currentSection, newSection) {
        case (.complete, .active):
            currentSteps = 0
            isFav = false
        case (.complete, .fav):
            currentSteps = 0
            isFav = true
        case (_, .complete):
            currentSteps = totalSteps
        case (.fav, .active):
            isFav = false
        case (.active, .fav):
            isFav = true

        case (.fav, .fav), (.active, .active):
            Log.fatal("Shouldn't be reachable")
        }
        Log.assert(section == newSection, message: "Messed up a goal section transition")
    }
}


// MARK: - Queries

extension Goal {

    /// For the main goals view -- all goals.
    static func allSortedResultsSet(model: Model) -> ModelResultsSet {
        return sectionatedResultsSet(model: model, predicate: nil)
    }

    // To do searching we need various different queries depending on the
    // scope bar setting for name/tag/either.

    /// Predicate to match goal name - contains
    static func getNameMatchPredicate(name str: String) -> NSPredicate {
        return NSPredicate(format: "\(#keyPath(name)) CONTAINS[cd] \"\(str)\"")
    }

    /// Magic string we use to represent the set of goals without a tag
    static let untaggedPlaceholder = "(untagged)"

    /// Predicate to match tag - supports exact with '=' prefix
    static func getTagMatchPredicate(tag str: String) -> NSPredicate {
        if str == "=" || str == "=\(untaggedPlaceholder)" {
            return NSPredicate(format: "\(#keyPath(tag)) == nil")
        } else if str.first == "=" {
            return NSPredicate(format: "\(#keyPath(tag)) LIKE[cd] \"\(str.dropFirst())\"")
        } else {
            return NSPredicate(format: "\(#keyPath(tag)) CONTAINS[cd] \"\(str)\"")
        }
    }

    /// Query - search by name
    static func searchByNameSortedResultsSet(model: Model, name: String) -> ModelResultsSet {
        return sectionatedResultsSet(model: model, predicate: getNameMatchPredicate(name: name))
    }

    /// Query - search by tag
    static func searchByTagSortedResultsSet(model: Model, tag: String) -> ModelResultsSet {
        return sectionatedResultsSet(model: model, predicate: getTagMatchPredicate(tag: tag))
    }

    /// Query - search by either
    static func searchByAnythingSortedResultsSet(model: Model, text: String) -> ModelResultsSet {
        let namePredicate = getNameMatchPredicate(name: text)
        let tagPredicate = getTagMatchPredicate(tag: text)
        let orPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [namePredicate, tagPredicate])
        return sectionatedResultsSet(model: model, predicate: orPredicate)
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

// MARK: - Tag Queries
extension Goal {

    private static func createTagsFieldFetchRequest(predicate: NSPredicate? = nil) -> ModelFieldFetchRequest {
        return createFieldFetchRequest(predicate: predicate, fields: [#keyPath(tag)], unique: true)
    }

    static var allTagsFieldFetchRequest: ModelFieldFetchRequest {
        return createTagsFieldFetchRequest()
    }

    static var completeTagsFieldFetchRequest: ModelFieldFetchRequest {
        let predicate = NSPredicate(format: "\(#keyPath(sectionOrder)) == \(Section.complete.rawValue)")
        return createTagsFieldFetchRequest(predicate: predicate)
    }

    static var incompleteTagsFieldFetchRequest: ModelFieldFetchRequest {
        let predicate = NSPredicate(format: "\(#keyPath(sectionOrder)) != \(Section.complete.rawValue)")
        return createTagsFieldFetchRequest(predicate: predicate)
    }

    static func decodeTagsResults(results: ModelFieldResults) -> [String] {
        return results.compactMap { ($0.values.first as? String) ?? untaggedPlaceholder }
    }
}

// MARK: - Summary steps for home screen

extension Goal {

    /// Private strings used to collect results
    private static let totalSumName = "sumCdTotalSteps"
    private static let currentSumName = "sumCdCurrentSteps"

    /// Helper
    private static func getSumExpressionDescription(keyPath: String, sumFieldName: String) -> NSExpressionDescription {
        let sumDescription = NSExpressionDescription()
        sumDescription.name = sumFieldName
        sumDescription.expression = NSExpression(format: "@sum.\(keyPath)")
        sumDescription.expressionResultType = .integer32AttributeType
        return sumDescription
    }

    /// For the total number of completed and current steps
    static var stepsSummaryFieldFetchRequest: ModelFieldFetchRequest {
        let totalSumDescr = getSumExpressionDescription(keyPath: #keyPath(cdTotalSteps),
                                                        sumFieldName: totalSumName)

        let currentSumDescr = getSumExpressionDescription(keyPath: #keyPath(cdCurrentSteps),
                                                          sumFieldName: currentSumName)

        return createFieldFetchRequest(fields: [totalSumDescr, currentSumDescr])
    }

    /// Decode the results when back from the DB
    static func decodeStepsSummary(results: ModelFieldResults) -> (current: Int, total: Int) {
        guard results.count == 1,
            let current = results[0][currentSumName] as? Int32,
            let total = results[0][totalSumName] as? Int32 else {
                Log.log("Odd steps summary data back from DB: \(results)")
                return (current: 0, total: 0)
        }
        return (current: Int(current), total: Int(total))
    }
}
