//
//  Epoch.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

extension Epoch : ModelObject {
    /// Framework default sort order for find/query
    public static let defaultSortDescriptor = NSSortDescriptor(key: "cdStartDate", ascending: true)

    /// This is more of a uniquing key.
    static let primarySortOrder = ModelSortOrder(keyName: "sortOrder")

    /// Default properties
    static func createWithDefaults(model: Model) -> Epoch {
        let epoch = create(from: model)
        epoch.name = ""
        epoch.startDate = .distantPast
        epoch.endDate = .distantFuture
        epoch.sortOrder = getNextSortOrderValue(primarySortOrder, from: model)
        return epoch
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

