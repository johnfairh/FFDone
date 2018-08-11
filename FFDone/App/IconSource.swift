//
//  IconSource.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

/// This file wraps up the way of getting an art asset 'icon' from
/// a third party web service.
///
/// It includes management of the view part, the network requests,
/// and any processing off the back of the requests needed to get
/// to a UIImage.
///
/// Details of the services are mostly abstracted into the resource
/// files; `IconEditViewController` is the main client and has a simple
/// hard-coded UI layout supporting just two sources.

import TMLPresentation

/// Properties of an icon source
struct IconSourceTemplate: CustomStringConvertible {
    let name: String
    let isSimple: Bool
    let urlBase: String
    let urlExtension: String
    let isUserName: Bool

    var description: String {
        return "Template=[\(name) \(isSimple) \(urlBase) \(urlExtension) \(isUserName)"
    }
}

/// Namespace
enum IconSourceBuilder {
    /// Stashed templates
    static var templates: [IconSourceTemplate] = []

    /// Add a template, called during app init
    static func addTemplate(_ template: IconSourceTemplate) {
        Log.debugLog(template.description)
        templates.append(template)
    }

    /// Create and begin management of some UI components as icon sources
    static func createSources(uiList: [IconSourceUI], delegate: IconSourceDelegate) -> [IconSource] {
        var sources: [IconSource] = []

        for (index, template) in templates.enumerated() {
            let ui = uiList[index]
            if template.isSimple {
                sources.append(SimpleIconSource(ui: ui, template: template, delegate: delegate))
            } else {
                sources.append(RestSearchIconSource(ui: ui, template: template, delegate: delegate))
            }
        }
        
        return sources
    }
}

/// Callbacks from icon source to give feedback on the fetch
protocol IconSourceDelegate: class {
    func setIconImage(iconSource: IconSource, image: UIImage)
    func setIconError(iconSource: IconSource, message: String)
}

/// UI elements to be customized for the icon source
struct IconSourceUI {
    weak var label: UILabel!
    weak var textField: UITextField!
    weak var button: UIButton!
}

/// Wrap up the UI for an icon source - text field, button, network stuff.
///
/// This is abstract, subclasses go to specific places.
class IconSource: NSObject, UITextFieldDelegate {
    private      let ui: IconSourceUI
                 let template: IconSourceTemplate
    private weak var delegate: IconSourceDelegate?

    /// Current fetcher, subclasses should use to make cancel work.
    var fetcher: URLFetcher?

    /// API: create at view load, waits for button/textfield enter
    fileprivate init(ui: IconSourceUI,
                     template: IconSourceTemplate,
                     delegate: IconSourceDelegate) {
        self.ui = ui
        self.template = template
        self.delegate = delegate
        super.init()
        ui.label.text = template.name
        ui.button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        ui.textField.delegate = self
        update()
    }

    /// Subclass helper - feedback to delegate
    func delegateImage(_ image: UIImage) {
        delegate?.setIconImage(iconSource: self, image: image)
    }

    /// Subclass helper - feedback to delegate
    func delegateError(_ message: String) {
        delegate?.setIconError(iconSource: self, message: message)
    }

    /// API - current text identifying the item
    var text: String {
        return ui.textField.text ?? ""
    }

    /// API - is the identifying text suitable for a icon object name?
    var textIsSuitableIconName: Bool {
        return template.isUserName
    }

    /// Refresh control enable state
    private func update() {
        ui.button.isEnabled = !text.isEmpty
    }

    /// API - cancel any network activity
    func cancel() {
        fetcher?.cancel()
        fetcher = nil
    }

    /// Text field delegate: return key prompts fetch
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if !text.isEmpty {
            Dispatch.toForeground {
                self.buttonTapped(self.ui.button)
            }
        }
        textField.resignFirstResponder()
        return true
    }

    /// Text field delegate: refresh UI
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        update()
        return true
    }

    /// Buttonpress - cancel any active fetch and start a new one
    @objc func buttonTapped(_ sender: UIButton) {
        cancel()
        getIcon()
    }

    /// Extension point, subclasses override
    func getIcon() {
        Log.fatal("Supposed to override this")
    }

    /// Subclass helper - get + return an icon at an URL
    func fetchIcon(urlString: String) {
        fetcher = URLFetcher(url: urlString) { data, error in
            if let data = data {
                if let image = UIImage(data: data, scale: 1.0) {
                    self.delegateImage(image)
                } else {
                    self.delegateError("Bad image data.")
                }
            } else if let error = error {
                self.delegateError(error)
            } else {
                Log.fatal("Error missing?")
            }
        }
    }
}

/// Helpers for clients dealing with arrays of sources
extension Array where Element == IconSource {
    func cancel() {
        forEach { $0.cancel() }
    }
}

/// Simple model - user has to locate the item ID through the web so we can just
/// plug it directly into the URL.
///
private class SimpleIconSource: IconSource {
    override func getIcon() {
        fetchIcon(urlString: "\(template.urlBase)\(text)\(template.urlExtension)")
    }
}

/// REST search model - a REST search interface that we can bash through.
/// Details of the API not at all abstracted!
///
private class RestSearchIconSource: IconSource {
    override func getIcon() {
        guard let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            self.delegateError("Can't encode the text")
            return
        }
        fetcher = URLFetcher(url: "\(template.urlBase)\(encoded)") { data, error in
            guard self.fetcher != nil else {
                // user cancelled
                return
            }

            if let data = data {
                self.handleJSON(data: data)
            } else if let error = error {
                self.delegateError(error)
            } else {
                Log.fatal("Error missing?")
            }
        }
    }

    func handleJSON(data: Data) {
        do {
            let object = try JSONSerialization.jsonObject(with: data)
            guard let topDict = object as? NSDictionary,
                let itemsDict = topDict["items"] as? NSDictionary,
                let resultsList = itemsDict["results"] as? NSArray,
                resultsList.count > 0,
                let firstResultDict = resultsList[0] as? NSDictionary,
                let iconUrl = firstResultDict["icon"] as? String else {
                    delegateError("Unexpected JSON format.")
                    return
            }
            fetchIcon(urlString: iconUrl)
        } catch {
            delegateError("Can't decode JSON: \(error)")
        }
    }
}
