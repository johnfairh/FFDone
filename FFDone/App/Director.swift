//
//  Director.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

// The Director is the top-level Presenter for the application.
// Although it does know a few things about view controllers
//
// It is roughly associated with the tab bar view and is responsible for
// configuring each tab with its own presenter.
//
// It offers services to all presenters to begin other use cases or access
// app-wide function.

// MARK: - Use-case request interface

enum DirectorRequest {
    case createGoal(Model)
    case editGoal(Goal, Model)
    case editGoalAndThen(Goal, Model, (Goal) -> Void)
    case viewGoal(Goal, Model)

    case switchToGoals(String)

    case createIcon(Model)
    case editIcon(Icon, Model)
    case pickIcon(Model, (Icon) -> Void)

    case createNote(Goal, Model)
    case createNoteAndThen(Goal, Model, (Note) -> Void)
    case editNote(Note, Model)
}

protocol DirectorInterface {
    /// Start a new usecase
    func request(_ request: DirectorRequest)
    
    /// What tags are defined?
    var tags: [String] { get }
}

// MARK: - Concrete director class

class Director {

    enum Tab: Int {
        case home = 0
        case goals = 1
        case notes = 2
        case alarms = 3
        case icons = 4
    }

    weak var services: TabbedDirectorServices<DirectorInterface>!
    private var rootModel: Model!
    private var tagList: TagList?

    init() {
    }

    func modelIsReady(model: Model) {
        rootModel = model
        tagList = TagList(model: model)

        Log.log("Director.modelIsReady")

        // set tabs
        initTab(.home,
                queryResults: Goal.allSortedResultsSet(model: model), // TODO: wot?
                presenterFn: HomePresenter.init)

        initTab(.goals,
                queryResults: Goal.allSortedResultsSet(model: model),
                presenterFn: GoalsTablePresenter.init) {
                    [unowned self] goal in self.request(.viewGoal(goal!, model))
        }

        initTab(.notes,
                queryResults: Note.allSortedResultsSet(model: model),
                presenterFn: NotesTablePresenter.init) {
                    [unowned self] note in self.request(.editNote(note!, model))
        }

        initTab(.alarms,
                queryResults: Alarm.sectionatedResultsSet(model: model),
                presenterFn: AlarmsTablePresenter.init) {
                    [unowned self] alarm in Log.log("Edit alarm: \(alarm!) (\(self))")
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
                                                         picked: @escaping PresenterDone<ModelObjectType> = { _ in })
        where ModelObjectType: ModelObject,PresenterType: Presenter {
            services.initTab(tabIndex: tab.rawValue,
                             rootModel: rootModel!,
                             queryResults: queryResults,
                             presenterFn: presenterFn,
                             picked: picked)
    }
}

// MARK: - DirectorRequest processing

extension DirectorRequest {
    func handle(services: TabbedDirectorServices<DirectorInterface>) {
        switch self {
        case let .editGoal(goal, model):
            DirectorRequest.editGoalAndThen(goal, model, { _ in }).handle(services: services)
        case let .editGoalAndThen(goal, model, continuation):
            services.editThing("GoalEditViewController",
                               model: model,
                               object: goal,
                               presenterFn: GoalEditPresenter.init,
                               done: { editGoal in continuation(editGoal) })

        case let .viewGoal(goal, model):
            services.viewThing("GoalViewController",
                               model: model,
                               object: goal,
                               presenterFn: GoalViewPresenter.init)

        case let .createGoal(model):
            services.createThing("GoalEditViewController",
                                 model: model,
                                 presenterFn: GoalEditPresenter.init,
                                 done: { _ in })

        case let .switchToGoals(tag):
            services.animateToTab(tabIndex: Director.Tab.goals.rawValue,
                                  invocationData: tag as AnyObject)

        case let .createIcon(model):
            services.createThing("IconEditViewController",
                                 model: model,
                                 presenterFn: IconEditPresenter.init,
                                 done: { _ in })

        case let .editIcon(icon, model):
            services.editThing("IconEditViewController",
                               model: model,
                               object: icon,
                               presenterFn: IconEditPresenter.init,
                               done: { _ in } )

        case let .pickIcon(model, continuation):
            services.pickThing("IconsTableViewController",
                               model: model,
                               results: Icon.createAllResults(model: model),
                               presenterFn: IconsTablePresenter.init,
                               done: continuation)

        case let .editNote(note, model):
            services.editThing("NoteEditViewController",
                               model: model,
                               object: note,
                               presenterFn: NoteEditPresenter.init,
                               done: { _ in })

        case let .createNote(goal, model):
            DirectorRequest.createNoteAndThen(goal, model, { _ in }).handle(services: services)
        case let .createNoteAndThen(goal, model, continuation):
            services.createThing("NoteEditViewController",
                                 model: model,
                                 presenterFn: NoteEditPresenter.init,
                                 done: { note in note.goal = goal; continuation(note) })

        }
    }
}

extension Director: DirectorInterface {
    /// Called from presenters to begin a new use-case
    func request(_ request: DirectorRequest) {
        // We add a fibre break here to avoid very odd behaviours, eg.
        // multi-second delays on selecting a table row.
        Dispatch.toForeground {
            request.handle(services: self.services)
        }
    }

    /// Call from presenter to query list of user-defined goal tags
    var tags: [String] {
        return tagList?.tags ?? []
    }
}
