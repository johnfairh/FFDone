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

    /// Create a fresh `Alarm` - ends up active
    static func createWithDefaults(model: Model) -> Alarm {
        let alarm = Alarm.create(from: model)
        alarm.sortOrder = Alarm.getNextSortOrderValue(primarySortOrder, from: model)
        alarm.name = ""
        alarm.kind = .weekly(3)
        alarm.icon = Icon.getGoalDefault(model: model) // XXX
        alarm.activate() // surely??
        
        return alarm
    }
}

// MARK: - Alarm kinds

extension Alarm {
    enum Kind {
        case oneShot
        case daily
        case weekly(Int)

        var repeatText: String {
            switch self {
            case .oneShot: return "Never"
            case .daily: return "Daily"
            case .weekly(_): return "Weekly"
            }
        }

        var repeatDay: Int? {
            if case let .weekly(day) = self {
                return day
            }
            return nil
        }
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
        refreshSectionOrder()
    }

    func deactivate() {
        nextActiveDate = computedNextActiveDate
        refreshSectionOrder()
    }

    func debugDeactivate() {
        if App.debugMode {
            nextActiveDate = Date().addingTimeInterval(10)
            refreshSectionOrder()
        } else {
            deactivate()
        }
    }

    public override func awakeFromFetch() {
        super.awakeFromFetch()
        refreshSectionOrder()
    }

    private func refreshSectionOrder() {
        if nextActiveDate == Alarm.activeNextActiveDate {
            sectionOrder = Section.active.rawValue
        } else {
            sectionOrder = Section.inactive.rawValue
        }
    }

    private static let utcCalendar: Calendar  = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    var computedNextActiveDate: Date {
        let components: DateComponents
        switch kind {
        case .daily:
            // Daily reset is 3PM GMT (midnight JST but I would get confused about which day it was)
            components = DateComponents(hour: 15, minute: 0)
            break
        case .weekly(let day):
            // Weekly reset is 8AM GMT, assume that will do
            components = DateComponents(hour: 8, minute: 0, weekday: day)
        case .oneShot:
            Log.fatal("Oneshot never next active")
        }

        guard let nextDate = Alarm.utcCalendar.nextDate(after: Date(),
                                                        matching: components,
                                                        matchingPolicy: .nextTime) else {
            Log.fatal("Can't find the next date? \(components)")
        }

        return nextDate
    }
}

// MARK: - Captions

extension Alarm {

    var text: String {
        return name ?? "(no title)"
    }

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

    var notificationText: String {
        let frequency: String
        switch kind {
        case .daily:
            frequency = "daily"
        case .weekly(_):
            frequency = "weekly"
        case .oneShot:
            Log.fatal("Can't notify oneShot alarms")
        }
        return text + " - " + frequency
    }
}

// MARK: - Image

extension Alarm {
    var mainTableImage: UIImage {
        return icon!.getStandardImage()
    }

    var nativeImage: UIImage {
        return icon!.nativeImage
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

    /// Get the alarms that are due (ish)
    static func findDueAlarms(model: Model) -> [Alarm] {
        let nextActive = #keyPath(cdNextActiveDate)
        let predicate = NSPredicate(format: "\(nextActive) > %@ AND \(nextActive) <= %@",
                                    argumentArray: [Alarm.activeNextActiveDate, Date().addingTimeInterval(5)])
        return findAll(model: model, predicate: predicate)
    }

    /// Query How many alarms are active
    static func getActiveAlarmCount(model: Model) -> Int {
        let nextActive = #keyPath(cdNextActiveDate)
        let predicate = NSPredicate(format: "\(nextActive) == %@", argumentArray: [Alarm.activeNextActiveDate])
        return count(model: model, predicate: predicate)
    }
}
