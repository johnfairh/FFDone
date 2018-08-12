//
//  Director.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

enum DirectorRequest {
    case createGoal(Model)
    case editGoal(Goal, Model)
    case viewGoal(Goal, Model)

    case createIcon(Model)
    case editIcon(Icon, Model)
    case pickIcon(Model, (Icon) -> Void)

    case createNote(Goal, Model)
    case editNote(Note, Model)
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
                    [unowned self] goal in self.request(.viewGoal(goal!, model))        /// TODO - view-goal
        }

        initTab(.notes,
                queryResults: Note.allSortedResultsSet(model: model),
                presenterFn: NotesTablePresenter.init) {
                    [unowned self] note in self.request(.editNote(note!, model))
        }

        initTab(.icons,
                queryResults: Icon.createAllResultsSet(model: model),
                presenterFn: IconsTablePresenter.init) {
                    [unowned self] icon in self.request(.editIcon(icon!, model))
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

            case let .viewGoal(goal, model):
                self.services.viewThing("GoalViewController",
                                        model: model,
                                        object: goal,
                                        presenterFn: GoalViewPresenter.init)

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

            case let .editIcon(icon, model):
                self.services.editThing("IconEditViewController",
                                        model: model,
                                        object: icon,
                                        presenterFn: IconEditPresenter.init,
                                        done: { _ in } )

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
