//
//  Strings.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import UIKit

enum Strings {
    enum Notification {
        /// Also referenced in the Info.plist of the notification content extension
        static let CATEGORY = "ALARM"
    }

    enum Color {
        static let text = "TextColour"
        static let tint = "TintColour"
        static let contentBg = "ContentBgColour"
    }
}

extension UIColor {
    static let text = UIColor(named: Strings.Color.text)!
    static let tint = UIColor(named: Strings.Color.tint)!
    static let contentBg = UIColor(named: Strings.Color.contentBg)
}
