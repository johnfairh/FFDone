//
//  HomePresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

// Presenter stack for the home tab.

// MARK: Pager -- the parent class that manages the pages

final class HomePagerPresenter: PagerPresenter<DirectorInterface, Epoch, HomePresenter>,
                                Presenter,
                                PagerPresenterInterface {
    typealias PagePresenter = HomePresenter
    typealias ViewInterfaceType = HomePagerPresenter//Interface

    init(director: DirectorInterface,
         model: Model,
         object: ModelResultsSet?,
         mode: PresenterMode,
         dismiss: @escaping PresenterDone<Epoch>) {
        super.init(director: director, model: model, object: object, mode: mode, pagePresenterFn: HomePresenter.init)
    }

    public var pageIndex: Int {
        get {
            director.homePageIndex
        }
        set {
            director.homePageIndex = newValue
        }
    }
}

// MARK: - Home Page -- pie + cloud

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
@MainActor
protocol HomePresenterInterface {
    /// Get told about data model changes
    var refresh: (HomeData) -> Void { get set }

    /// Get the heading image ID
    var headingImage: UIImage? { get }

    /// Get the heading overlay text
    var headingOverlayText: String? { get }

    /// Drill down into a tag
    func displayTag(_ tag: String)

    /// New goal
    func createGoal()

    /// New alarm
    func createAlarm()

    /// Show the epochs manager
    func showEpochs()
}

class HomePresenter: Presenter, HomePresenterInterface {
    typealias ViewInterfaceType = HomePresenterInterface

    private let model: Model
    private let director: DirectorInterface

    private let epoch: Epoch

    private var tasks: [Task<Void, Never>] = []

    required init(director: DirectorInterface, model: Model, object: Epoch?, mode: PresenterMode, dismiss: @escaping PresenterDone<Epoch>) {
        Log.assert(mode.isSingleType(.edit))
        guard let object = object else {
            Log.fatal("Missing epoch object to HomePresenter!")
        }
        self.model = model
        self.director = director
        self.epoch = object

        tasks.append(Task { [weak self] in
            for await results in model.fieldResultsSequence(Goal.stepsSummaryFieldFetchRequest(in: epoch)) {
                self?.updateStepsQueryResults(results: results)
            }
        })

        tasks.append(Task { [weak self] in
            for await results in model.fieldResultsSequence(Goal.completeTagsFieldFetchRequest(in: epoch)) {
                self?.updateTags(.complete, results: results)
            }
        })

        tasks.append(Task { [weak self] in
            for await results in model.fieldResultsSequence(Goal.incompleteTagsFieldFetchRequest(in: epoch)) {
                self?.updateTags(.incomplete, results: results)
            }
        })
    }

    deinit {
        tasks.forEach { $0.cancel() }
    }

    var headingImage: UIImage? {
        return epoch.image
    }

    var headingOverlayText: String? {
        epoch.isGlobal ? nil : epoch.versionText
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
        let data = GoalsTableInvocationData(epoch: epoch, tagged: tag)
        director.request(.switchToGoals(data))
    }

    func createGoal() {
        director.request(.createGoal(model))
    }

    func createAlarm() {
        director.request(.createAlarm(model))
    }

    func showEpochs() {
        director.request(.showEpochs)
    }
}
