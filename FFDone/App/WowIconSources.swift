//
//  WowIconSources.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

//
// Icon sources for World of Warcraft
//

/// Icon source to grab an icon by name from Wowhead
fileprivate final class WowheadIconSource: BaseNetworkIconSource, IconSource {
    var name = "Wowhead"

    var inputDescription = "Icon Name"

    func findIcon(name: String, client: @escaping (IconSourceResult) -> Void) {
        fetchIcon(at: "https://wow.zamimg.com/images/wow/icons/large/\(name.lowercased()).jpg", client: client)
    }
}


/// Namespace
enum WowIconSources {
    // Called once by IconSource to publish our available sources
    static func install() {
        IconSourceBuilder.install(source: WowheadIconSource(), name: "Wowhead")
    }
}
