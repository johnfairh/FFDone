//
//  ColorHelpers.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

extension UIColor {
    static let tint = UIColor(named: Strings.Color.tint)!
    static let tableLeadingSwipe = UIColor(named: Strings.Color.tableLeadingSwipe)
    static let tagBubble = UIColor(named: Strings.Color.tagBubble)!
    static let pieComplete = UIColor(named: Strings.Color.pieComplete)!
    static let pieIncomplete = UIColor(named: Strings.Color.pieIncomplete)!
    static let veryLightText = UIColor(named: Strings.Color.veryLightText)!
}

enum ColorScheme {
    static func globalInit() {
        // stuff bizarrely unaffected by 'global' tint
        UITabBar.appearance().tintColor = .tint
        UINavigationBar.appearance().tintColor = .tint
        UIPageControl.appearance().currentPageIndicatorTintColor = .tint

        // defaults to black! which messes up the lightmode tabbar on the
        // home screen that has a VC that does not extend beneath it...
        //  - neither of these work, see SceneDelegate hack instead :(
        // UIWindow.appearance().backgroundColor = .systemBackground
        // UIApplication.shared.windows.forEach { $0.backgroundColor = .systemBackground }

        // badges
        UIImage.badgeColor = .veryLightText

        // defaults to white!
        UIPageControl.appearance().backgroundColor = .systemBackground
    }
}
