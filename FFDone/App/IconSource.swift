//
//  IconSource.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

/// This is a registry and coordinator for icon sources: typically a
/// third-party web service that returns a graphic given a string identifier.
///
/// All known sources are initialized once - this is basically free, nothing
/// happens.
///
/// The icon sources config file says which sources should be activated and
/// presented to the UI to actually use.

import TMLPresentation

/// Type returned by an `IconSource` lookup request.
typealias IconSourceResult = TMLResult<UIImage>

/// Callback type for clients that want images.
typealias IconSourceClient = (IconSourceResult) -> Void

/// Model a service that asynchronously provides images in response to string keys.
protocol IconSource {
    /// Human-readable name for the service, used as a label.
    var name: String { get }

    /// Human-readable name for the service's parameter, used as textfield background.
    var inputDescription: String { get }

    /// Kick off an async request to fetch an image.
    func findIcon(name: String, client: @escaping IconSourceClient)

    /// Cancel any pending request.
    func cancel()
}

/// Namespace to handle the double-sided pub-sub.
enum IconSourceBuilder {
    /// All sources
    static private var allSources: [String : IconSource] = [:]

    /// Active sources
    static private(set) var sources: [IconSource] = []

    /// Dumb Swift mechanism to trigger one-time registration
    static private let sourceOnce: Void = {
        XivIconSources.install()
    }()

    /// Register a named icon source, called by sources at start-of-day [in theory]
    static func install(source: IconSource, name: String) {
        allSources[name.lowercased()] = source
    }

    /// Activate a particular icon source, called at config-file read-time.
    static func activateSource(name: String) {
        let _ = sourceOnce // one-time registration

        guard let source = allSources[name.lowercased()] else {
            let sourceNames = allSources.keys.joined(separator: ", ")
            Log.log("Unknown icon source \(name), ignoring.  Have sources: \(sourceNames)")
            return
        }
        sources.append(source)
    }

    /// Cancel any background activity
    static func cancelAll() {
        sources.forEach { $0.cancel() }
    }
}

/// Helper class for sources that access icons via http.
class BaseNetworkIconSource {
    /// HTTP wrapper
    var fetcher: URLFetcher?

    /// Typically witnesses `IconSource.cancel()`
    func cancel() {
        fetcher?.cancel()
        fetcher = nil
    }

    /// Helper - get + return an icon at an URL
    func fetchIcon(at urlString: String, client: @escaping IconSourceClient) {
        fetcher = URLFetcher(url: urlString) { result in
            client(result.flatMap { data in
                if let image = UIImage(data: data, scale: 1.0) {
                    return .success(image)
                } else {
                    return .failure("Bad image data.")
                }
            })
        }
    }
}
