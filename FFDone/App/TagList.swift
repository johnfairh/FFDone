//
//  TagList.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Central place to cache the names of all the tags in use.
/// This is used for auto-completion when the user is entering a tag name.
final class TagList {
    var tags: [String]
    private var runner: ModelFieldWatcher

    init(model: Model) {
        tags = []
        runner = model.createFieldWatcher(fetchRequest: Goal.allTagsFieldFetchRequest)
        runner.callback = { [unowned self] results in
            self.tags = Goal.decodeTagsResults(results: results)
        }
    }
}
