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
    static func create(model: Model, shortName: String, longName: String, majorVersion: Int, minorVersion: Int) -> Epoch {
        let epoch = createWithDefaults(model: model)
        epoch.cdShortName = shortName
        epoch.cdLongName = longName
        epoch.minorVersion = Int64(minorVersion)
        epoch.majorVersion = Int64(majorVersion)
        return epoch
    }

    /// Special global epoch
    private static var globalShortName = "All"

    static func createGlobal(model: Model, longName: String) -> Epoch {
        let epoch = create(model: model, shortName: globalShortName, longName: longName, majorVersion: 1, minorVersion: 0)
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
}

// MARK: - Version

extension Epoch {
    var versionText: String {
        "\(majorVersion).\(minorVersion)"
    }
}

// MARK: - Names

extension Epoch {
    var shortName: String {
        cdShortName ?? ""
    }

    var longName: String {
        cdLongName ?? ""
    }
}

// MARK: - Latest

extension Epoch {
    static func mostRecent(in model: Model) -> Epoch {
        let results = createAllResults(model: model)
        guard let epoch = results.fetchedObjects?.last as? Epoch else {
            Log.fatal("Missing any epochs")
        }
        return epoch
    }
}
