//
//  XivIconSources.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

//
// Icon sources for Final Fantasy XIV
//

/// Icon source to grab an icon by ID from garland tools.
fileprivate final class GarlandDbIconSource: BaseNetworkIconSource, IconSource {
    var name: String {
        return "Garland Tools"
    }

    func findIcon(name: String, client: @escaping (IconSourceResult) -> Void) {
        fetchIcon(at: "https://www.garlandtools.org/files/icons/item/\(name).png", client: client)
    }
}

/// Icon source to search the XIV API items database by name
fileprivate final class XivApiIconSource: BaseNetworkIconSource, IconSource {
    var name: String {
        return "XIV API items"
    }

    func findIcon(name: String, client: @escaping (IconSourceResult) -> Void) {
        guard let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            client(.failure("Can't encode the text"))
            return
        }
        let base = "https://xivapi.com/"
        let searchUrl = "\(base)/search?indexes=Item&string=\(encoded)"

        fetcher = URLFetcher(url: searchUrl) { result in
            switch result {
            case .failure(let error):
                client(.failure(error))
            case .success(let data):
                guard let jsonObject = try? JSONSerialization.jsonObject(with: data) else {
                    client(.failure(TMLError("Can't decode as JSON: \(data)")))
                    return
                }
                guard let topDict = jsonObject as? NSDictionary,
                    let resultsList = topDict["Results"] as? NSArray else {
                    client(.failure(TMLError("Can't decode top-level JSON format: \(jsonObject)")))
                    return
                }

                guard resultsList.count > 0 else {
                    client(.failure("No matches found."))
                    return
                }

                guard let firstResultsDict = resultsList[0] as? NSDictionary,
                    let iconUrlPath = firstResultsDict["Icon"] as? String else {
                    client(.failure(TMLError("Can't decode 2nd-level JSON format: \(resultsList[0])")))
                    return
                }
                self.fetchIcon(at: "\(base)\(iconUrlPath)", client: client)
            }
        }
    }
}

/// Namespace
enum XivIconSources {
    // Called once by IconSource to publish our available sources
    static func install() {
        IconSourceBuilder.install(source: GarlandDbIconSource(), name: "Garland")
        IconSourceBuilder.install(source: XivApiIconSource(), name: "XIVAPI")
    }
}
