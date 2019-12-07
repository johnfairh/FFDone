//
//  ColorHelpers.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

extension UIColor {
//    static let text = UIColor(named: Strings.Color.text)!
    static let tint = UIColor(named: Strings.Color.tint)!
//    static let tableHeader = UIColor(named: Strings.Color.tableHeader)
//    static let tableSeparator = UIColor(named: Strings.Color.tableSeparator)
//    static let tableHighlight = tableSeparator
    static let tableLeadingSwipe = UIColor(named: Strings.Color.tableLeadingSwipe)
//    static let background = UIColor(named: Strings.Color.background)!
    static let tagBubble = UIColor(named: Strings.Color.tagBubble)!
    static let pieComplete = UIColor(named: Strings.Color.pieCompleteColor)!
    static let pieIncomplete = UIColor(named: Strings.Color.pieIncompleteColor)!
}

// Dark color scheme stuff.
//
// This was very fiddly to get through.  Couldn't figure out what mix of run-time / storyboard to do,
// and for run-time how much to push into custom classes and how much extensions.
//
// If doing this again from scratch I would use a lot more in the storyboard and custom controls.

extension UIViewController {
    func setBasicColors() {
        view.tintColor = .tint
    }
}

enum ColorScheme {
    static func globalInit() {
        // tabbar
        UITabBar.appearance().tintColor = .tint

        // navbar
        UINavigationBar.appearance().tintColor = .tint
        UISearchBar.appearance().tintColor = .tint

        // badges
        UIImage.badgeColor = .secondaryLabel

        // pagecontrol (dots)
        UIPageControl.appearance().currentPageIndicatorTintColor = .tint
        UIPageControl.appearance().backgroundColor = .systemBackground
    }
}
