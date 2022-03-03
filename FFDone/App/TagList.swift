//
//  TagList.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Quick wrapper, Sendable vs. MainActor
private final class ModelBox: @unchecked Sendable {
    let model: Model
    init(_ model: Model) { self.model = model }
}

/// Central place to cache the names of all the tags in use.
/// This is used for auto-completion when the user is entering a tag name.
@MainActor
final class TagList {
    var tags: [String] = []

    init(app: App) {
        app.notifyWhenReady { model in
            let box = ModelBox(model)
            Task { @MainActor in
                for await results in box.model.fieldResultsSequence(Goal.allTagsFieldFetchRequest) {
                    self.tags = Goal.decodeTagsResults(results: results)
                }
            }
        }
    }
}
