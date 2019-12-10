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

    enum UserActivityType {
        /// Also referenced in the Info.plist
        static let stateRestoration = "com.tml.ffdone.activity.StateRestoration"
    }

    enum Color {
        static let tint = "TintColour" // FF gold
        static let veryLightText = "VeryLightTextColour"
        static let tagBubble = "TagBackgroundColour" // V light blue
        static let pieIncomplete = "PieRedColour"
        static let pieComplete = "PieGreenColour"
        static let tableLeadingSwipe = "StepSwipeColour"
    }
}
