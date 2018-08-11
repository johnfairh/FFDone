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

    case createIcon(Model)
    case pickIcon(Model, (Icon) -> Void)

    case editNote(Note, Model)
    case createNote(Goal, Model)
}

protocol DirectorInterface {
    func request(_ request: DirectorRequest)
}

class Director {

    enum Tab: Int {
        case goals = 0
        case notes = 1
        case icons = 2
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

        initTab(.notes,
                queryResults: Note.allSortedResultsSet(model: model),
                presenterFn: NotesTablePresenter.init) {
                    [unowned self] note in self.request(.editNote(note!, model))
        }

        initTab(.icons,
                queryResults: Icon.createAllResultsSet(model: model),
                presenterFn: IconsTablePresenter.init) { [unowned self] icon in
                    Log.log("Selected: \(self) \(icon!)")
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
                                        done: { _ in App.shared.refreshTags() })

            case let .createGoal(model):
                self.services.createThing("GoalEditViewController",
                                          model: model,
                                          presenterFn: GoalEditPresenter.init,
                                          done: { _ in App.shared.refreshTags() })

            case let .createIcon(model):
                self.services.createThing("IconEditViewController",
                                          model: model,
                                          presenterFn: IconEditPresenter.init,
                                          done: { _ in })

            case let .pickIcon(model, continuation):
                self.services.pickThing("IconsTableViewController",
                                        model: model,
                                        results: Icon.createAllResults(model: model),
                                        presenterFn: IconsTablePresenter.init,
                                        done: continuation)

            case let .editNote(note, model):
                self.services.editThing("NoteEditViewController",
                                        model: model,
                                        object: note,
                                        presenterFn: NoteEditPresenter.init,
                                        done: { _ in })

            case let .createNote(goal, model):
                self.services.createThing("NoteEditViewController",
                                          model: model,
                                          presenterFn: NoteEditPresenter.init,
                                          done: { note in note.goal = goal })
            }
        }
    }
}
