//
//  HomePresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

// This is a somewhat different screen that takes data inputs from
// various queries and combines that into a bespoke type `HomeData`
// that is passed to the UI.

struct HomeSideData {
    let tags: [String]
    let steps: Int
}

enum HomeSideType: Int {
    case complete = 0
    case incomplete = 1

    var other: HomeSideType {
        switch self {
        case .incomplete: return .complete
        case .complete: return .incomplete
        }
    }
}

typealias HomeData = [HomeSideType: HomeSideData]

extension Dictionary where Key == HomeSideType, Value == HomeSideData {
    func dataForSide(_ side: HomeSideType) -> HomeSideData {
        return self[side]!
    }
}

/// Presenter inputs, commands, outputs
protocol HomePresenterInterface {

    /// Get told about data model changes
    var refresh: (HomeData) -> Void { get set }

    /// Drill down into a tag
    func displayTag(_ tag: String)

    /// New goal
    func createGoal()

    /// New alarm
    func createAlarm()

    /// Show the settings window
    func showSettings()
}

class HomePresenter: Presenter, HomePresenterInterface {
    typealias ViewInterfaceType = HomePresenterInterface

    private let model: Model
    private let director: DirectorInterface

    private let stepsFieldWatcher: ModelFieldWatcher
    private let completeTagsFieldWatcher: ModelFieldWatcher
    private let incompleteTagsFieldWatcher: ModelFieldWatcher

    convenience init(director: DirectorInterface, model: Model) {
        self.init(director: director, model: model, object: nil, mode: .single(.view), dismiss: { _ in })
    }

    required init(director: DirectorInterface, model: Model, object: ModelResultsSet?, mode: PresenterMode, dismiss: @escaping PresenterDone<Goal>) {
        self.model = model
        self.director = director

        self.stepsFieldWatcher = model.createFieldWatcher(fetchRequest: Goal.stepsSummaryFieldFetchRequest)
        self.completeTagsFieldWatcher = model.createFieldWatcher(fetchRequest: Goal.completeTagsFieldFetchRequest)
        self.incompleteTagsFieldWatcher = model.createFieldWatcher(fetchRequest: Goal.incompleteTagsFieldFetchRequest)

        self.stepsFieldWatcher.callback = { [weak self] results in
            self?.updateStepsQueryResults(results: results)
        }

        self.completeTagsFieldWatcher.callback = { [weak self] results in
            self?.updateTags(.complete, results: results)
        }

        self.incompleteTagsFieldWatcher.callback = { [weak self] results in
            self?.updateTags(.incomplete, results: results)
        }
    }

    // MARK: - Steps + Tags

    // Stash the step sums
    private var currentSteps = 0
    private var totalSteps = 0

    // When the DB tells us stuff has changed, update our cache + refresh the view
    func updateStepsQueryResults(results: ModelFieldResults) {
        let decoded = Goal.decodeStepsSummary(results: results)
        currentSteps = decoded.current
        totalSteps = decoded.total
        doRefresh()
    }

    // Stash the tags lists
    private var tagLists: [HomeSideType : [String]] = [:]

    func updateTags(_ type: HomeSideType, results: ModelFieldResults) {
        tagLists[type] = Goal.decodeTagsResults(results: results)
        doRefresh()
    }

    var refresh: (HomeData) -> Void = { _ in } {
        didSet {
            doRefresh()
        }
    }

    // Database updates come in batches, do a bit of merging to be kind to the UI

    private var refreshDeglitching = false

    private func doRefresh() {
        if !refreshDeglitching {
            refreshDeglitching = true
            Dispatch.toForegroundAfter(milliseconds: 20) {
                self.refreshDeglitching = false
                var homeData = HomeData()
                homeData[.complete] = HomeSideData(tags: self.tagLists[.complete] ?? [],
                                                   steps: self.currentSteps)
                homeData[.incomplete] = HomeSideData(tags: self.tagLists[.incomplete] ?? [],
                                                     steps: self.totalSteps - self.currentSteps)
                self.refresh(homeData)
            }
        }
    }

    // MARK: - User interactions

    // user clicks tag
    func displayTag(_ tag: String) {
        director.request(.switchToGoals(tag))
    }

    func createGoal() {
        director.request(.createGoal(model))
    }

    func createAlarm() {
        director.request(.createAlarm(model))
    }

    func showSettings() {
        director.request(.showSettings)
    }
}
