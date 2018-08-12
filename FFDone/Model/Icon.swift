//
//  Icon.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

extension Icon : ModelObject {
    /// Framework default sort order for find/query
    public static let defaultSortDescriptor = NSSortDescriptor(key: "sortOrder", ascending: true)

    /// Allow user reordering
    static let primarySortOrder = ModelSortOrder(keyName: "sortOrder")

    /// Default properties, no image or name.
    static func createWithDefaults(model: Model) -> Icon {
        let icon = Icon.create(from: model)
        icon.name = ""
        icon.isDefault = false
        icon.isBuiltin = false
        icon.sortOrder = getNextSortOrderValue(primarySortOrder, from: model)
        return icon
    }

    /// The Icon's image at its native size.
    var nativeImage: UIImage {
        get {
            return imageData as! UIImage
        }
        set {
            imageData = newValue
        }
    }

    /// Has the Icon been configured with an image?  Used during create/edit.
    var hasImage: Bool {
        return imageData != nil
    }

    /// Has the Icon been configured with a name?
    var hasName: Bool {
        return name != nil && !name!.isEmpty
    }

    /// Standard Icon size is 43x43, fits nicely in a standard `UITableView` row.
    static let standardSize = CGSize(width: 43, height: 43)

    /// Badging is optional and puts a nice small label on top of the image.
    func getStandardImage(withBadge badge: String? = nil) -> UIImage {
        return nativeImage.imageWithSize(Icon.standardSize, andBadge: badge)
    }

    /// Default goal icon
    static func getGoalDefault(model: Model) -> Icon {
        let predicate = NSPredicate(format: "isDefault == 1")
        guard let defaultIcon = findFirst(model: model, predicate: predicate) else {
            Log.fatal("No default icon")
        }
        return defaultIcon
    }

    /// For the search view -- search icon name.
    static func searchByNameSortedResultsSet(model: Model, str: String) -> ModelResultsSet {
        let nameMatchPredicate = NSPredicate(format: "\(#keyPath(name)) CONTAINS[cd] \"\(str)\"")

        return createFetchedResults(model: model,
                                    predicate: nameMatchPredicate,
                                    sortedBy: [defaultSortDescriptor],
                                    sectionNameKeyPath: nil).asModelResultsSet
    }
}
