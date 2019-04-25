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

struct IconSourceError: Error, ExpressibleByStringLiteral { // -> TMLError along with URLFetcher
    let text: String
    init(stringLiteral text: String) { self.text = text }
    init(_ text: String)             { self.init(stringLiteral: text) }
}

typealias IconSourceResult = Result<UIImage, IconSourceError>

typealias IconSourceClient = (IconSourceResult) -> Void

protocol IconSource {
    var name: String { get }
    func findIcon(name: String, client: @escaping IconSourceClient)
    func cancel()
}

/// Namespace
enum IconSourceBuilder {
    /// Sources
    static private(set) var sources: [IconSource] = []

    static func addSource(name: String) {
        switch name.lowercased() {
        case "garland": sources.append(GarlandDbIconSource())
//        case "xivapi": sources.append(XivApiIconSource())
        default: Log.log("Unknown icon source \(name) - ignoring")
        }
    }

    static func cancelAll() {
        sources.forEach { $0.cancel() }
    }
}

class BaseNetworkIconSource {
    var fetcher: URLFetcher?

    /// Fulfills `IconSource.cancel()`
    func cancel() {
        fetcher?.cancel()
        fetcher = nil
    }

    /// Helper - get + return an icon at an URL
    func fetchIcon(at urlString: String, client: @escaping IconSourceClient) {
        fetcher = URLFetcher(url: urlString) { data, error in
            if let data = data {
                if let image = UIImage(data: data, scale: 1.0) {
                    client(.success(image))
                } else {
                    client(.failure("Bad image data."))
                }
            } else if let error = error {
                client(.failure(IconSourceError(error)))
            } else {
                Log.fatal("Error missing?")
            }
        }
    }
}


fileprivate final class GarlandDbIconSource: BaseNetworkIconSource, IconSource {
    var name: String {
        return "Garland Tools"
    }

    func findIcon(name: String, client: @escaping (IconSourceResult) -> Void) {
        fetchIcon(at: "https://www.garlandtools.org/files/icons/item/\(name).png", client: client)
    }
}

/// REST search model - a REST search interface that we can bash through.
/// Details of the API not at all abstracted!
///
//private class RestSearchIconSource: IconSource {
//    override func getIcon() {
//        guard let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
//            self.delegateError("Can't encode the text")
//            return
//        }
//        fetcher = URLFetcher(url: "\(template.urlBase)\(encoded)") { data, error in
//            guard self.fetcher != nil else {
//                // user cancelled
//                return
//            }
//
//            if let data = data {
//                self.handleJSON(data: data)
//            } else if let error = error {
//                self.delegateError(error)
//            } else {
//                Log.fatal("Error missing?")
//            }
//        }
//    }
//
//    func handleJSON(data: Data) {
//        do {
//            let object = try JSONSerialization.jsonObject(with: data)
//            guard let topDict = object as? NSDictionary,
//                let itemsDict = topDict["items"] as? NSDictionary,
//                let resultsList = itemsDict["results"] as? NSArray,
//                resultsList.count > 0,
//                let firstResultDict = resultsList[0] as? NSDictionary,
//                let iconUrl = firstResultDict["icon"] as? String else {
//                    delegateError("Unexpected JSON format.")
//                    return
//            }
//            fetchIcon(urlString: iconUrl)
//        } catch {
//            delegateError("Can't decode JSON: \(error)")
//        }
//    }
//}
