//
//  Icon.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

//
// ValueTransformer to store images as JPEGs in the database
//
final class IconImageTransformer : ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return UIImage.self
    }

    override class func allowsReverseTransformation() -> Bool {
        return true
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let image = value as? UIImage else {
            fatalError("Image transformer confused")
        }
        return image.jpegData(compressionQuality: 1.0)
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else {
            fatalError("Image transformer confused")
        }
        return UIImage(data: data)
    }

    static func startup() {
        ValueTransformer.setValueTransformer(IconImageTransformer(), forName: NSValueTransformerName(rawValue: "IconImageTransformer"))
    }
}

final class Icon : NSManagedObject, ModelObject {
    static let defaultSortDescriptor = NSSortDescriptor(key: "sortOrder", ascending: true)
    static let primarySortOrder = ModelSortOrder(keyName: "sortOrder")

    /// The Icon's image at its native size.
    var nativeImage : UIImage {
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
}

