//
//  Director.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

enum DirectorRequest {
    case editGoal(Goal, Model)
//    case editGoalAndThen(Goal, Model, (Goal) -> Void)
    case createGoal(Model)
//    case createGoalAndThen(Model, (Goal) -> Void)

    case pickIcon(Model, (Icon) -> Void)
}

protocol DirectorInterface {
    func request(_ request: DirectorRequest)
}

class Director {

    enum Tab: Int {
        case goals = 0
        case icons = 1
        case notes = 2
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
                queryResults: Goal.allSortedResultsSet(model: model),
                presenterFn: GoalsTablePresenter.init) {
                    [unowned self] goal in self.request(.editGoal(goal!, model))        /// TODO - view-goal
        }

        initTab(.icons,
                queryResults: Icon.createAllResultsSet(model: model),
                presenterFn: IconsTablePresenter.init) { [unowned self] icon in
                    Log.log("Selected: \(self) \(icon!)")
        }

        initTab(.notes,
                queryResults: Note.allSortedResultsSet(model: model),
                presenterFn: NotesTablePresenter.init) {
                    [unowned self] note in self.request(.editGoal(note!.goal!, model))  /// TODO - view-goal
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
        // We add a fibre break here to avoid very odd behaviours, eg.
        // multi-second delays on selecting a table row.
        Dispatch.toForeground {
            switch request {
            case let .editGoal(goal, model):
                self.services.editThing("GoalEditViewController",
                                        model: model,
                                        object: goal,
                                        presenterFn: GoalEditPresenter.init,
                                        done: { _ in })

            case let .createGoal(model):
                self.services.createThing("GoalEditViewController",
                                          model: model,
                                          presenterFn: GoalEditPresenter.init,
                                          done: { _ in })

            case let .pickIcon(model, continuation):
                self.services.pickThing("IconsTableViewController",
                                        model: model,
                                        results: Icon.createAllResults(model: model),
                                        presenterFn: IconsTablePresenter.init,
                                        done: continuation)
            }
        }
    }
}
