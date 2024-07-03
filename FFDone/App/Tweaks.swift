//
//  Tweaks.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

// Misc things that diverge between game configs.

struct Tweaks: Sendable {
    let stateRestorationKey: String
    let epochImageHeight: Int
    let globalEpochName: String

    private init(stateRestorationKey: String = "",
                 epochImageHeight: Int = 0,
                 globalEpochName: String = "") {
        self.stateRestorationKey = stateRestorationKey
        self.epochImageHeight = epochImageHeight
        self.globalEpochName = globalEpochName
    }

    nonisolated(unsafe)
    static var shared = Tweaks()

    @MainActor
    static func globalInit() {
        guard let tweaks = DatabaseObjects.readTweaks() else {
            return
        }
        shared = Tweaks(stateRestorationKey: tweaks.str("state_restoration_key"),
                        epochImageHeight: tweaks.int("epoch_image_height"))
    }
}
