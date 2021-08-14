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
    var name = "Garland Tools"

    var inputDescription = "Icon ID"

    func findIcon(name: String) async throws -> UIImage {
        try await fetchIcon(at: "https://www.garlandtools.org/files/icons/item/\(name).png")
    }
}

/// Icon source to search the XIV API items database by name
fileprivate final class XivApiIconSource: BaseNetworkIconSource, IconSource {
    var name = "XIV API"

    var inputDescription = "Item name"

    func findIcon(name: String) async throws -> UIImage {
        guard let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw TMLError("Can't encode the text")
        }
        let base = "https://xivapi.com/"
        let searchUrl = "\(base)search?indexes=Item&string=\(encoded)"

        let data = try await URLFetcher(url: searchUrl).fetch()

        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) else {
            throw TMLError("Can't decode as JSON: \(data)")
        }

        guard let topDict = jsonObject as? NSDictionary,
            let resultsList = topDict["Results"] as? NSArray else {
                throw TMLError("Can't decode top-level JSON format: \(jsonObject)")
        }

        guard resultsList.count > 0 else {
            throw TMLError("No matches found.")
        }

        guard let firstResultsDict = resultsList[0] as? NSDictionary,
            let iconUrlPath = firstResultsDict["Icon"] as? String else {
            throw TMLError("Can't decode 2nd-level JSON format: \(resultsList[0])")
        }

        return try await fetchIcon(at: "\(base)\(iconUrlPath)")
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
