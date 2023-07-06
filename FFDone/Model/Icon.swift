//
//  Icon.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

var imageCache: [Int64:UIImage] = [:]

extension Icon : ModelObject {
    /// Framework default sort order for find/query
    public static let defaultSortDescriptor = NSSortDescriptor(key: "sortOrder", ascending: true)

    /// Allow user reordering
    static let primarySortOrder = ModelSortOrder(keyName: "sortOrder")

    /// Default properties, no image or name.
    static func createWithDefaults(model: Model) -> Icon {
        let icon = Icon.create(from: model)
        icon.name = ""
        icon.isBuiltin = false
        icon.sortOrder = getNextSortOrderValue(primarySortOrder, from: model)
        return icon
    }

    /// The Icon's image at its native size.
    var nativeImage: UIImage {
        get {
            if let image = imageCache[sortOrder] {
                return image
            }
            let image = UIImage(data: imageData!)!
            imageCache[sortOrder] = image
            return image
        }
        set {
            imageData = newValue.pngData()
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

    func getBadgedImage(size: CGSize, badge: String? = nil) -> UIImage {
        return nativeImage.imageWithSize(size, andBadge: badge)
    }

    /// Default goal icon
    static func getGoalDefault(model: Model) -> Icon {
        return getSpecific(model: model, named: Prefs.defaultGoalIcon)
    }

    var isGoalDefault: Bool {
        get {
            return name == Prefs.defaultGoalIcon
        }
        set {
            if newValue {
                Prefs.defaultGoalIcon = name!
            } else if isGoalDefault {
                Prefs.defaultGoalIcon = ""
            }
        }
    }

    static func getAlarmDefault(model: Model) -> Icon {
        return getSpecific(model: model, named: Prefs.defaultAlarmIcon)
    }

    var isAlarmDefault: Bool {
        get {
            return name == Prefs.defaultAlarmIcon
        }
        set {
            if newValue {
                Prefs.defaultAlarmIcon = name!
            } else if isAlarmDefault {
                Prefs.defaultAlarmIcon = ""
            }
        }
    }

    private static func getSpecific(model: Model, named: String) -> Icon {
        if let defaultIcon = find(from: model, named: named) {
            return defaultIcon
        }
        // if not found then just return something...
        let fallback = NSPredicate(format: "\(#keyPath(isBuiltin)) == TRUE")
        if let defaultIcon = findFirst(model: model, predicate: fallback) {
            return defaultIcon
        }
        Log.fatal("Can't find default icon")
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
