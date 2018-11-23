//
//  Note.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

extension Note: ModelObject {
    /// Framework default sort order for find/query
    public static let defaultSortDescriptor = NSSortDescriptor(key: #keyPath(cdCreationDate), ascending: false)

    static func createWithDefaults(model: Model) -> Note {
        let note = Note.create(from: model)
        note.text = ""
        note.creationDate = Date()
        return note
    }

    /// Create a new Note based on this one
    func dup(model: Model) -> Note {
        let note = Note.createWithDefaults(model: model)
        note.text = text
        return note
    }

    // MARK: - Daystamp conversion

    // For core data section-sorting we have to maintain a separate day timestamp field,
    // stored as a string.  We have to convert it to user-readable later on.
    // Use a couple of formatters and some kludging.

    private static var dayStampFormatter: DateFormatter = {
        // because timezones and leap seconds and suchlike this is technically wrong,
        // but it is good enough for our purposes.
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()

    private static var userDayStampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    /// Take a daystamp string used by core data to sectionate note tables
    /// and turn it into a string suitable for display to the user.
    static func dayStampToUserString(dayStamp: String) -> String {
        guard dayStamp.count == 8 else {
            return "A mystery date (\(dayStamp))"
        }

        let monthIndex = dayStamp.index(dayStamp.startIndex, offsetBy: 4)
        let dayIndex = dayStamp.index(dayStamp.startIndex, offsetBy: 6)
        let year = dayStamp[..<monthIndex]
        let month = dayStamp[monthIndex..<dayIndex]
        let day = dayStamp[dayIndex..<dayStamp.endIndex]

        let dc = DateComponents(year: Int(year)!, month: Int(month)!, day: Int(day)!)
        guard let date = Calendar.current.date(from: dc) else {
            return "Another mystery date (\(dayStamp))"
        }

        return Note.userDayStampFormatter.string(from: date)
    }

    /// Convert a `Date` to an 8-char datestamp
    static func dateToDayStamp(date: Date) -> String {
        return dayStampFormatter.string(from: date)
    }

    /// Full timestamp associated with the date - used mostly for sorting.
    /// As a side effect, update the daystamp.
    var creationDate: Date {
        get {
            return Date(timeIntervalSinceReferenceDate: cdCreationDate)
        }
        set {
            cdCreationDate = newValue.timeIntervalSinceReferenceDate
            dayStamp = Note.dateToDayStamp(date: newValue)
        }
    }
}

// MARK: - Queries

extension Note {

    /// For the main history view -- all notes.
    static func allSortedResultsSet(model: Model) -> ModelResultsSet {
        return sectionatedResultsSet(model: model, predicate: nil, latestFirst: false)
    }

    static func allReverseSortedResultsSet(model: Model) -> ModelResultsSet {
        return sectionatedResultsSet(model: model, predicate: nil, latestFirst: true)
    }

    /// For the search view -- search note text content.
    static func searchByTextSortedResultsSet(model: Model, str: String) -> ModelResultsSet {
        let textMatchPredicate = NSPredicate(format: "\(#keyPath(text)) CONTAINS[cd] \"\(str)\"")

        return sectionatedResultsSet(model: model, predicate: textMatchPredicate, latestFirst: false)
    }

    /// For the per-note view.
    static func perGoalResultsSet(model: Model, goal ofGoal: Goal) -> ModelResultsSet {
        let goalMatchPredicate = NSPredicate(format: "\(#keyPath(goal)) == %@", ofGoal)
        return sectionatedResultsSet(model: model, predicate: goalMatchPredicate, latestFirst: !ofGoal.isComplete)
    }

    /// Carefully sorted to drive the table
    private static func sectionatedResultsSet(model: Model, predicate: NSPredicate?, latestFirst: Bool) -> ModelResultsSet {
        // Filter out alarm notes..
        let goalsOnlyPredicate = NSPredicate(format: "\(#keyPath(goal)) != NIL")
        let goalsPredicate: NSPredicate
        if let predicate = predicate {
            goalsPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, goalsOnlyPredicate])
        } else {
            goalsPredicate = goalsOnlyPredicate
        }

        // Day, most recent first
        let dayOrder = NSSortDescriptor(key: #keyPath(dayStamp), ascending: !latestFirst)

        // Time within day, most recent first
        let timeOrder = NSSortDescriptor(key: #keyPath(cdCreationDate), ascending: !latestFirst)

        return createFetchedResults(model: model,
                                    predicate: goalsPredicate,
                                    sortedBy: [dayOrder, timeOrder],
                                    sectionNameKeyPath: #keyPath(dayStamp)).asModelResultsSet
    }
}

extension Goal {
    func notesResults(model: Model) -> ModelResultsSet {
        return Note.perGoalResultsSet(model: model, goal: self)
    }
}
