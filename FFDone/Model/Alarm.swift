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
        alarm.kind = AlarmSet.shared.weeklyReset(day: 3)
        alarm.icon = Icon.getAlarmDefault(model: model)
        alarm.activeNote = Note.createWithDefaults(model: model)
        alarm.defaultNote = Note.createWithDefaults(model: model)
        alarm.activate()
        
        return alarm
    }
}

// MARK: - Alarm kinds

extension Alarm {
    enum Kind {
        case oneShot
        case xivDaily
        case xivDailyGc
        case xivWeekly(Int)
        case wowDaily
        case wowWeekly(Int)

        var repeatText: String {
            switch self {
            case .oneShot: return "Never"
            case .xivDaily, .wowDaily: return "Daily Reset"
            case .xivDailyGc: return "Daily GC Reset"
            case .xivWeekly(_), .wowWeekly(_): return "Weekly"
            }
        }

        var repeatDay: Int? {
            switch self {
            case .xivWeekly(let day), .wowWeekly(let day):
                return day
            default:
                return nil
            }
        }

        static let xivDefaults: [Kind] = [
            .oneShot,
            .xivWeekly(3),
            .xivDaily,
            .xivDailyGc,
        ]

        static let wowDefaults: [Kind] = [
            .oneShot,
            wowWeekly(3),
            wowDaily
        ]
    }

    var kind: Kind {
        set {
            switch newValue {
            case .oneShot:
                cdType = 0
                cdWeekDay = 1
            case .xivDaily:
                cdType = 1
                cdWeekDay = 1
            case .xivWeekly(let day):
                cdType = 2
                cdWeekDay = Int16(day)
            case .xivDailyGc:
                cdType = 3
                cdWeekDay = 1;
            case .wowDaily:
                cdType = 4
                cdWeekDay = 1
            case .wowWeekly(let day):
                cdType = 5
                cdWeekDay = Int16(day)
            }
        }
        get {
            switch cdType {
            case 0: return .oneShot
            case 1: return .xivDaily
            case 2: return .xivWeekly(Int(cdWeekDay))
            case 3: return .xivDailyGc
            case 4: return .wowDaily
            case 5: return .wowWeekly(Int(cdWeekDay))
            default:
                // Let's not crash
                return .oneShot
            }
        }
    }
}

enum AlarmSet: String {
    case xiv
    case wow

    var kinds: [Alarm.Kind] {
        switch self {
        case .xiv: return Alarm.Kind.xivDefaults
        case .wow: return Alarm.Kind.wowDefaults
        }
    }

    func weeklyReset(day: Int) -> Alarm.Kind {
        switch self {
        case .xiv: return .xivWeekly(day)
        case .wow: return .wowWeekly(day)
        }
    }

    static var shared = AlarmSet.xiv
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
        notes = defaultNotes
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
        case .xivDaily:
            // Daily reset is 3PM GMT (midnight JST but I would get confused about which day it was)
            components = DateComponents(hour: 15, minute: 0)
            break
        case .xivDailyGc:
            // GC Daily reset is 2000 GMT for some reason
            components = DateComponents(hour: 20, minute: 0)
            break
        case .xivWeekly(let day):
            // Weekly reset is 8AM GMT, assume that will do
            components = DateComponents(hour: 8, minute: 0, weekday: day)
        case .wowDaily:
            // Daily reset is 7AM GMT
            components = DateComponents(hour: 7, minute: 0)
        case .wowWeekly(let day):
            // Weekly reset also 7AM GMT
            components = DateComponents(hour: 7, minute: 0, weekday: day)
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
            case .xivDaily, .xivDailyGc, .wowDaily:
                return "Repeats daily"
            case .xivWeekly(let day), .wowWeekly(let day):
                return "Repeats every \(getWeekdayName(day: day))"
            }
        } else {
            var cap = dueDateString + ", then "
            switch kind {
            case .xivDaily, .xivDailyGc, .wowDaily: cap += "daily"
            case .xivWeekly(_), .wowWeekly(_): cap += "weekly"
            case .oneShot: Log.fatal("Inactive oneshot?")
            }
            return cap
        }
    }

    var notificationText: String {
        let frequency: String
        switch kind {
        case .xivDaily, .xivDailyGc, .wowDaily:
            frequency = "daily"
        case .xivWeekly(_), .wowWeekly(_):
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

// MARK: - Notes

extension Alarm {
    var notes: String {
        get {
            return activeNote?.text ?? ""
        }
        set {
            guard let note = activeNote else {
                Log.fatal("No activeNote object for alarm \(self)")
            }
            note.text = newValue
        }
    }

    var defaultNotes: String {
        get {
            return defaultNote?.text ?? ""
        }
        set {
            guard let note = defaultNote else {
                Log.fatal("No defaultNote object for alarm \(self)")
            }
            note.text = newValue
        }
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
