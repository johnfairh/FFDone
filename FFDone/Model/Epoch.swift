//
//  Epoch.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

extension Epoch : ModelObject {
    /// Framework default sort order for find/query
    public static let defaultSortDescriptor = NSSortDescriptor(key: #keyPath(cdStartDate), ascending: true)

    /// This is more of a uniquing key.
    static let primarySortOrder = ModelSortOrder(keyName: "sortOrder")

    /// Default properties
    static func createWithDefaults(model: Model) -> Epoch {
        let epoch = create(from: model)
        epoch.startDate = Date()
        epoch.endDate = .distantFuture
        epoch.sortOrder = getNextSortOrderValue(primarySortOrder, from: model)
        return epoch
    }

    /// Custom properties
    static func create(model: Model, shortName: String, longName: String, majorVersion: Int64, minorVersion: Int64) -> Epoch {
        let epoch = createWithDefaults(model: model)
        epoch.cdShortName = shortName
        epoch.cdLongName = longName
        epoch.minorVersion = Int64(minorVersion)
        epoch.majorVersion = Int64(majorVersion)
        return epoch
    }

    /// Defaults to next patch
    static func createFrom(previous: Epoch, in model: Model) -> Epoch {
        create(model: model,
               shortName: previous.shortName,
               longName: previous.longName,
               majorVersion: previous.majorVersion,
               minorVersion: previous.minorVersion + 1)
    }

    var canSave: Bool {
        !shortName.isEmpty && !longName.isEmpty && majorVersion > 0
    }

    /// Special global epoch
    private static var globalShortName = "All"

    static func createGlobal(model: Model, longName: String) -> Epoch {
        let epoch = create(model: model, shortName: globalShortName, longName: longName,
                           majorVersion: 1, minorVersion: 0)
        epoch.startDate = .distantPast
        return epoch
    }

    var isGlobal: Bool {
        shortName == Epoch.globalShortName && sortOrder == 1
    }
}

// MARK: - Timestamp wrapper utilities, allow `Date` in code and convert to TIs

extension Epoch {
    /// When the epoch starts
    var startDate: Date {
        get {
            return Date(timeIntervalSinceReferenceDate: cdStartDate)
        }
        set {
            cdStartDate = newValue.timeIntervalSinceReferenceDate
        }
    }

    /// When the epoch ends
    var endDate: Date {
        get {
            return Date(timeIntervalSinceReferenceDate: cdEndDate)
        }
        set {
            cdEndDate = newValue.timeIntervalSinceReferenceDate
        }
    }

    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateStyle = .long
        return formatter
    }()

    var startDateText: String {
        Epoch.dateFormatter.string(from: startDate)
    }

    private static var dateIntervalFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter()
        formatter.timeStyle = .none
        formatter.dateStyle = .long
        return formatter
    }()

    var dateIntervalText: String {
        if startDate == .distantPast {
            return ""
        }
        if endDate == .distantFuture {
            return startDateText
        }
        return Epoch.dateIntervalFormatter.string(from: startDate, to: endDate)
    }
}

// MARK: - Version

extension Epoch {
    var versionText: String {
        "\(majorVersion).\(minorVersion)"
    }

    func parse(version: String) -> Bool {
        guard let match = version.re_match(#"^(\d+)\.(\d+)$"#) else {
            return false
        }
        majorVersion = Int64(match[1])!
        minorVersion = Int64(match[2])!
        return true
    }
}

// MARK: - Names

extension Epoch {
    var shortName: String {
        get {
            cdShortName ?? ""
        }
        set {
            cdShortName = newValue
        }
    }

    var longName: String {
        get {
            cdLongName ?? ""
        }
        set {
            cdLongName = newValue
        }
    }
}

// MARK: - Latest

extension Epoch {
    static func mostRecent(in model: Model) -> Epoch {
        let results = findAll(model: model)
        guard let epoch = results.last else {
            Log.fatal("Missing any epochs")
        }
        return epoch
    }
}

// MARK: - Logo image

extension Epoch {
    var image: UIImage {
        UIImage(named: "EpochHeading_\(majorVersion)") ?? UIImage(named: "EpochHeading_1")!
    }
}

// MARK: - Merge

extension Epoch {
    static func merge(major: Int64, in model: Model) {
        let predicate = NSPredicate(format: "\(#keyPath(Epoch.majorVersion)) == %@", argumentArray: [major])
        let allInMajor = findAll(model: model, predicate: predicate, sortedBy: [defaultSortDescriptor])
        guard let first = allInMajor.first, let last = allInMajor.last, allInMajor.count > 1 else {
            return
        }
        first.endDate = last.endDate
        allInMajor[1...].forEach {
            model.delete($0)
        }
    }
}
