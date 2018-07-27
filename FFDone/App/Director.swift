//
//  Director.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

enum DirectorRequest {
    case editGoal(Goal, Model)
    case editGoalAndThen(Goal, Model, (Goal) -> Void)
}

protocol DirectorInterface {
    func request(_ request: DirectorRequest)
}

class Director {

    enum Tab: Int {
        case goals = 0
    }

    weak var services: TabbedDirectorServices<DirectorInterface>!
    private var rootModel: Model!

    init() {
    }

    func modelIsReady(model: Model) {
        rootModel = model

        Log.log("Director.modelIsReady")

        // set tabs
        initTab(.goals,
                queryResults: model.allGoalsResults.asModelResultsSet,
                presenterFn: GoalsTablePresenter.init) { [unowned self] goal in
                    Log.log("Selected: \(self) \(goal!)")
        }

        // Turn on the actual UI replacing the loading screen
        services.presentUI()
    }

    /// Helper to load + config the top-level table controllers
    private func initTab<ModelObjectType, PresenterType>(_ tab: Tab,
                                                         queryResults: ModelResultsSet,
                                                         presenterFn: MultiPresenterFn<DirectorInterface, ModelObjectType, PresenterType>,
                                                         picked: @escaping PresenterDone<ModelObjectType>)
        where ModelObjectType: ModelObject,PresenterType: Presenter {
            services.initTab(tabIndex: tab.rawValue,
                             rootModel: rootModel!,
                             queryResults: queryResults,
                             presenterFn: presenterFn,
                             picked: picked)
    }
}

extension Director: DirectorInterface {

    func request(_ request: DirectorRequest) {
        switch request {
        case let .editGoal(goal, model):
            Log.fatal("No idea how to edit a goal \(goal) \(model)")

        case let .editGoalAndThen(goal, model, continuation):
            Log.fatal("Still no idea how to edit a goal \(goal) \(model) \(continuation)")
        }
    }
}
