//
//  Tweaks.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

// Misc things that diverge between game configs.

struct Tweaks {
    let stateRestorationKey: String
    let epochImageHeight: Int

    private init(stateRestorationKey: String = "", epochImageHeight: Int = 0) {
        self.stateRestorationKey = stateRestorationKey
        self.epochImageHeight = epochImageHeight
    }

    static var shared = Tweaks()

    static func globalInit() {
        guard let tweaks = DatabaseObjects.readTweaks() else {
            return
        }
        shared = Tweaks(stateRestorationKey: tweaks.str("state_restoration_key"),
                        epochImageHeight: tweaks.int("epoch_image_height"))
    }
}
