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
        static let Category = "ALARM"
    }

    enum Color {
        static let text = "TextColour" // off-white
        static let tint = "TintColour" // FF gold
        static let background = "BackgroundColour" // Black
        static let tableHeader = "TableHeaderColour" // V dark grey
        static let tableSeparator = "TableSeparatorColour" // Lighter grey
        static let tagBubble = "TagBackgroundColour" // V light blue
    }
}

extension UIColor {
    static let text = UIColor(named: Strings.Color.text)!
    static let tint = UIColor(named: Strings.Color.tint)!
    static let tableHeader = UIColor(named: Strings.Color.tableHeader)
    static let tableSeparator = UIColor(named: Strings.Color.tableSeparator)
    static let tableHighlight = tableSeparator
    static let background = UIColor(named: Strings.Color.background)!
    static let tagBubble = UIColor(named: Strings.Color.tagBubble)!
}
