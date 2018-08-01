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

    /// The Icon's image at its native size.
    var nativeImage: UIImage {
        get {
            return imageData as! UIImage
        }
        set {
            imageData = newValue
        }
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
}
