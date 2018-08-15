//
//  HomePresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Presenter inputs, commands, outputs
protocol HomePresenterInterface {

    var refresh: (_ current: Int, _ total: Int) -> Void { get set }
}

class HomePresenter: Presenter, HomePresenterInterface, ModelFieldWatcherDelegate {
    typealias ViewInterfaceType = HomePresenterInterface

    private let query: ModelResultsSet
    private let model: Model
    private let director: DirectorInterface
    private let fieldWatcher: ModelFieldWatcher

    var refresh: (_ current: Int, _ total: Int) -> Void = { _, _ in } {
        didSet {
            doRefresh()
        }
    }

    required init(director: DirectorInterface, model: Model, object: ModelResultsSet?, mode: PresenterMode, dismiss: @escaping PresenterDone<Goal>) {
        Log.assert(mode.isMultiType(.manage) && object != nil)
        self.query    = object!
        self.model    = model
        self.director = director
        self.fieldWatcher = model.createFieldWatcher(fetchRequest: Goal.stepsSummaryFieldFetchRequest)
        self.fieldWatcher.delegate = self
    }

    // Stash the step sums
    private var current = 0
    private var total = 0

    // When the DB tells us stuff has changed, update our cache + refresh the view
    func updateQueryResults(results: ModelFieldResults) {
        let decoded = Goal.decodeStepsSummary(results: results)
        current = decoded.current
        total = decoded.total
        doRefresh()
    }

    // Push new state to the view
    private func doRefresh() {
        refresh(current, total)
    }
}
