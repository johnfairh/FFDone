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
    case dupGoal(Goal, Model)
    case viewGoal(Goal, Model)

    case switchToGoals(GoalsTableInvocationData)

    case createIcon(Model)
    case createIconAndThen(Model, (Icon) -> Void)
    case editIcon(Icon, Model)
    case pickIcon(Model, (Icon) -> Void)

    case createNote(Goal, Model)
    case createNoteAndThen(Goal, Model, (Note) -> Void)
    case editNote(Note, Model)
    case editNoteAndThen(Note, Model, (Note) -> Void)

    case createAlarm(Model)
    case editAlarm(Alarm, Model)
    case editAlarmAndThen(Alarm, Model, (Alarm) -> Void)
    case dupAlarm(Alarm, Model)
    case viewAlarm(Alarm, Model)
    case scheduleAlarmAndThen(Alarm, () -> Void)
    case cancelAlarm(String)
    case setActiveAlarmCount(Int)

    case showDebugConsole
    case showSettings
}

protocol DirectorInterface {
    /// Start a new usecase
    func request(_ request: DirectorRequest)
    
    /// What tags are defined?
    var tags: [String] { get }

    /// Query the debug log
    var debugLogCache: LogCache { get }

    /// Save/Restore the home page index [state save empire goes here]
    var homePageIndex: Int { get set }
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

    fileprivate let alarmScheduler: AlarmScheduler
    fileprivate let tagList: TagList
    weak var services: TabbedDirectorServices<DirectorInterface>!
    fileprivate var rootModel: Model!
    private let logCache: LogCache
    var homePageIndex: Int

    init(alarmScheduler: AlarmScheduler, tagList: TagList, logCache: LogCache, homePageIndex: Int) {
        self.alarmScheduler = alarmScheduler
        self.tagList = tagList
        self.logCache = logCache

        self.homePageIndex = homePageIndex
        App.shared.notifyWhenReady { model in
            self.modelIsReady(model: model)
        }
    }

    func modelIsReady(model: Model) {
        rootModel = model

        Log.log("Director.modelIsReady")

        // set tabs
        initTab(.home,
                queryResults: Epoch.createAllResultsSet(model: model),
                presenterFn: HomePagerPresenter.init)

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
                    [unowned self] alarm in self.request(.viewAlarm(alarm!, model))
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

    private func initTab<PresenterType>(_ tab: Tab,
                                        presenterFn: NulPresenterFn<DirectorInterface, PresenterType>)
        where PresenterType: Presenter {
            services.initTab(tabIndex: tab.rawValue,
                             rootModel: rootModel!,
                             presenterFn: presenterFn)
    }
}

// MARK: - DirectorRequest processing

extension DirectorRequest {
    func handle(director: Director) {
        let services = director.services!
        let alarmScheduler = director.alarmScheduler

        switch self {
        case let .editGoal(goal, model):
            DirectorRequest.editGoalAndThen(goal, model, { _ in }).handle(director: director)
        case let .editGoalAndThen(goal, model, continuation):
            services.editThing("GoalEditViewController",
                               model: model,
                               object: goal,
                               presenterFn: GoalEditPresenter.init,
                               done: { editGoal in continuation(editGoal) })

        case let .dupGoal(goal, model):
            services.createThing("GoalEditViewController",
                                 model: model,
                                 from: goal,
                                 presenterFn: GoalEditPresenter.init,
                                 done: { _ in })

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

        case let .switchToGoals(data):
            services.animateToTab(tabIndex: Director.Tab.goals.rawValue,
                                  invocationData: data as AnyObject)

        case let .createIcon(model):
            DirectorRequest.createIconAndThen(model, { _ in }).handle(director: director)
        case let .createIconAndThen(model, continuation):
            services.createThing("IconEditViewController",
                                 model: model,
                                 presenterFn: IconEditPresenter.init,
                                 done: continuation)

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
            DirectorRequest.editNoteAndThen(note, model, { _ in }).handle(director: director)
        case let .editNoteAndThen(note, model, continuation):
            services.editThing("NoteEditViewController",
                               model: model,
                               object: note,
                               presenterFn: NoteEditPresenter.init,
                               done: continuation)

        case let .createNote(goal, model):
            DirectorRequest.createNoteAndThen(goal, model, { _ in }).handle(director: director)
        case let .createNoteAndThen(goal, model, continuation):
            services.createThing("NoteEditViewController",
                                 model: model,
                                 presenterFn: NoteEditPresenter.init,
                                 done: { note in goal.add(note: note); continuation(note) })

        case let .createAlarm(model):
            services.createThing("AlarmEditViewController",
                                 model: model,
                                 presenterFn: AlarmEditPresenter.init,
                                 done: { _ in })
        case let .dupAlarm(alarm, model):
            services.createThing("AlarmEditViewController",
                                 model: model,
                                 from: alarm,
                                 presenterFn: AlarmEditPresenter.init,
                                 done: { _ in })
        case let .editAlarm(alarm, model):
            DirectorRequest.editAlarmAndThen(alarm, model, { _ in }).handle(director: director)
        case let .editAlarmAndThen(alarm, model, continuation):
            services.editThing("AlarmEditViewController",
                               model: model,
                               object: alarm,
                               presenterFn: AlarmEditPresenter.init,
                               done: continuation)

        case let .viewAlarm(alarm, model):
            services.viewThing("AlarmViewController",
                               model: model,
                               object: alarm,
                               presenterFn: AlarmViewPresenter.init)

        case let .scheduleAlarmAndThen(alarm, callback):
            alarmScheduler.scheduleAlarm(text: alarm.notificationText,
                                         image: alarm.nativeImage,
                                         for: alarm.nextActiveDate) { uid in
                                            if let uid = uid {
                                                alarm.notificationUid = uid
                                            }
                                            callback()
                                         }

        case let .cancelAlarm(uid):
            alarmScheduler.cancelAlarm(uid: uid)
        case let .setActiveAlarmCount(count):
            services.setTabBadge(tab: Director.Tab.alarms.rawValue, badge: (count == 0) ? nil : String(count))
            alarmScheduler.activeAlarmCount = count

        case .showDebugConsole:
            services.showNormally("DebugViewController",
                                  model: director.rootModel,
                                  presenterFn: DebugPresenter.init)
        case .showSettings:
            services.showModally("SettingsViewController",
                                 model: director.rootModel,
                                 presenterFn: SettingsPresenter.init,
                                 done: {})
        }
    }
}

extension Director: DirectorInterface {
    /// Called from presenters to begin a new use-case
    func request(_ request: DirectorRequest) {
        // We add a fibre break here to avoid very odd behaviours, eg.
        // multi-second delays on selecting a table row.
        Dispatch.toForeground {
            request.handle(director: self)
        }
    }

    /// Call from presenter to query list of user-defined goal tags
    var tags: [String] {
        return tagList.tags
    }

    /// Debug log
    var debugLogCache: LogCache {
        return logCache
    }
}
