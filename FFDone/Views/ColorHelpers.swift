//
//  ColorHelpers.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

extension UIColor {
    static let text = UIColor(named: Strings.Color.text)!
    static let tint = UIColor(named: Strings.Color.tint)!
    static let tableHeader = UIColor(named: Strings.Color.tableHeader)
    static let tableSeparator = UIColor(named: Strings.Color.tableSeparator)
    static let tableHighlight = tableSeparator
    static let tableLeadingSwipe = UIColor(named: Strings.Color.tableLeadingSwipe)
    static let background = UIColor(named: Strings.Color.background)!
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

// Text fields don't work so well with a dark background: the placeholder text and the clear image
// do not show up.  There are no proper APIs for accessing these so we resort to a couple of
// really nasty hacks from SO.
//
// The clear image in particular is a nightmare because it comes and goes depending on what the
// wider state of the textfield is - so we catch it at runtime and tweak it.
class DarkModeTextField: UITextField {
    override func awakeFromNib() {
        super.awakeFromNib()
        setValue(UIColor.darkGray, forKeyPath: "_placeholderLabel.textColor")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        for view in subviews {
            if let button = view as? UIButton {
                button.setImage(button.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
                button.tintColor = .white
            }
        }
    }
}

/// Setting this globally is a disaster because of all the random labels that are parts of
/// other system views.
extension UILabel {
    func setColors() {
        textColor = .text
    }
}

/// We have a couple of buttons that aren't tinted
extension UIButton {
    func setColors() {
        setTitleColor(.text, for: .normal)
    }
}

extension UIViewController {
    func setBasicColors() {
        view.tintColor = .tint
        view.backgroundColor = .background
    }
}

extension UITableViewController {
    /// Set up for a grouped dialog-style table
    func setFormTableColors() {
        setBasicColors()
        UITableViewCell.appearance(whenContainedInInstancesOf: [type(of: self)]).backgroundColor = .tableHeader
    }

    func setFlatTableColors() {
        setBasicColors()
        UITableViewCell.appearance(whenContainedInInstancesOf: [type(of: self)]).backgroundColor = .background//il
    }
}

extension UITableViewHeaderFooterView {
    func setFlatTableColors() {
        textLabel?.setColors()
    }

    func setColors() {
        setFlatTableColors()
        tintColor = .tableHeader // this sets the background color
    }
}

enum ColorScheme {
    static func globalInit() {
        // tabbar
        UITabBar.appearance().tintColor = .tint
        UITabBar.appearance().barTintColor = .background

        // navbar
        UINavigationBar.appearance().tintColor = .tint
        UINavigationBar.appearance().barTintColor = .background
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.text]
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.text]
        UISearchBar.appearance().tintColor = .tint

        // text controls
        UITextField.appearance().keyboardAppearance = .dark // textview equiv crashes :/
        UITextField.appearance().textColor = .text
        UITextView.appearance().textColor = .text

        // tables
        let selectedView = UIView()
        selectedView.backgroundColor = .tableHighlight
        UITableViewCell.appearance().selectedBackgroundView = selectedView
        UITableView.appearance().separatorColor = .tableSeparator

        // badges
        UIImage.badgeColor = .text
    }
}
