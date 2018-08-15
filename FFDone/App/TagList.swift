//
//  TagList.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

///
final class TagList: ModelFieldWatcherDelegate {
    var tags: [String]
    private var runner: ModelFieldWatcher

    init(model: Model) {
        tags = []
        runner = model.createFieldWatcher(fetchRequest: Goal.tagListFieldFetchRequest)
        runner.delegate = self
    }

    func updateQueryResults(results: ModelFieldResults) {
        tags = results.compactMap { $0.values.first as? String }
    }
}
