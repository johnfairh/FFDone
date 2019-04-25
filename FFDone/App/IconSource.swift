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

/// Type returned by an `IconSource` lookup request.
typealias IconSourceResult = TMLResult<UIImage>

/// Callback type for clients that want images.
typealias IconSourceClient = (IconSourceResult) -> Void

/// Model a service that asynchronously provides images in response to string keys.
protocol IconSource {
    /// Human-readable name for the service.
    var name: String { get }

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
