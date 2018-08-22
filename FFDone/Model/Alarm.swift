//
//  Alarm.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

extension Alarm: ModelObject {
    /// Framework default sort order for find/query
    public static let defaultSortDescriptor = NSSortDescriptor(key: #keyPath(sortOrder), ascending: false)

    /// Allow for user reordering
    static let primarySortOrder = ModelSortOrder(keyName: #keyPath(sortOrder), ascending: false)

    /// Magic value to mark active alarms, far past
    static private let activeNextActiveDate = Date(timeIntervalSinceReferenceDate: 0)

    /// Create a fresh `Alarm` - ends up inactive but unscheduled.
    static func createWithDefaults(model: Model) -> Alarm {
        let alarm = Alarm.create(from: model)
        alarm.sortOrder = Alarm.getNextSortOrderValue(primarySortOrder, from: model)
        alarm.name = ""
        alarm.kind = .weekly(1)
        alarm.icon = Icon.getGoalDefault(model: model) // XXX
        alarm.deactivate()
        
        return alarm
    }
}

// MARK: - Alarm kinds

extension Alarm {
    enum Kind {
        case oneShot
        case daily
        case weekly(Int)
    }

    var kind: Kind {
        set {
            switch newValue {
            case .oneShot:
                cdType = 0
                cdWeekDay = 1
            case .daily:
                cdType = 1
                cdWeekDay = 1
            case .weekly(let day):
                cdType = 2;
                cdWeekDay = Int16(day)
            }
        }
        get {
            switch cdType {
            case 0: return .oneShot
            case 1: return .daily
            case 2: return .weekly(Int(cdWeekDay))
            default:
                // Let's not crash
                return .oneShot
            }
        }
    }
}

// MARK: - Alarm activeness

extension Alarm {

    private(set) var nextActiveDate: Date {
        get {
            return Date(timeIntervalSinceReferenceDate: cdNextActiveDate)
        }
        set {
            cdNextActiveDate = newValue.timeIntervalSinceReferenceDate
        }
    }

    var isActive: Bool {
        return nextActiveDate == Alarm.activeNextActiveDate
    }

    enum Section: String {
        case active = "0"
        case inactive = "1"

        static var titleMap: [String : String] =
            ["0" : "Active",
             "1" : "Scheduled"]
    }

    func activate() {
        nextActiveDate = Alarm.activeNextActiveDate
        sectionOrder = Section.active.rawValue
    }

    func deactivate() {
        nextActiveDate = computedNextActiveDate
        sectionOrder = Section.inactive.rawValue
    }

    var computedNextActiveDate: Date {
        // Let's take 6AM GMT for the start of the day.
        var components = DateComponents(hour: 6, minute: 0)

        switch kind {
        case .daily:
            break
        case .weekly(let day):
            components.weekday = day
        case .oneShot:
            Log.fatal("Oneshot never next active")
        }

        guard let nextDate = Calendar.current.nextDate(after: Date(),
                                                       matching: components,
                                                       matchingPolicy: .nextTime) else {
            Log.fatal("Can't find the next date? \(components)")
        }

        return nextDate
    }
}

// MARK: - Caption

extension Alarm {

    var dueDateString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE MMM dd"
        return dateFormatter.string(from: nextActiveDate)
    }

    func getWeekdayName(day: Int) -> String {
        return Calendar.current.weekdaySymbols[day - 1 ]
    }

    var caption: String {
        if isActive {
            switch kind {
            case .oneShot:
                return ""
            case .daily:
                return "Repeats daily"
            case .weekly(let day):
                return "Repeats every \(getWeekdayName(day: day))"
            }
        } else {
            var cap = dueDateString + ", then "
            switch kind {
            case .daily: cap += "daily"
            case .weekly(_): cap += "weekly"
            case .oneShot: Log.fatal("Inactive oneshot?")
            }
            return cap
        }
    }
}

// MARK: - Image

extension Alarm {
    var mainTableImage: UIImage {
        return icon!.getStandardImage()
    }
}

// MARK: - Queries

extension Alarm {
    /// Sorted into sections for the main table
    static func sectionatedResultsSet(model: Model) -> ModelResultsSet {
        // Active -> Inactive (active -> field is 0)
        let sectionsOrder = NSSortDescriptor(key: #keyPath(cdNextActiveDate), ascending: true)

        // User sort order, affects active alarms that share the same timestamp
        let userSortOrder = NSSortDescriptor(key: #keyPath(sortOrder), ascending: false)

        return createFetchedResults(model: model,
                                    predicate: nil,
                                    sortedBy: [sectionsOrder, userSortOrder],
                                    sectionNameKeyPath: #keyPath(sectionOrder)).asModelResultsSet
    }
}
