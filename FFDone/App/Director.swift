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

enum DirectorResult {
    case none
    case goal(Goal)
    case icon(Icon)
    case note(Note)
    case alarm(Alarm)
    init(goal: Goal) { self = .goal(goal) }
    init(icon: Icon) { self = .icon(icon) }
    init(note: Note) { self = .note(note) }
    init(alarm: Alarm) { self = .alarm(alarm) }

    var goal: Goal {
        guard case let .goal(goal) = self else { Log.fatal("not goal") }
        return goal
    }

    var icon: Icon {
        guard case let .icon(icon) = self else { Log.fatal("not icon") }
        return icon
    }

    var note: Note {
        guard case let .note(note) = self else { Log.fatal("not note") }
        return note
    }

    var alarm: Alarm {
        guard case let .alarm(alarm) = self else { Log.fatal("not alarm") }
        return alarm
    }
}

enum DirectorRequest {
    case createGoal(Model)
    case editGoal(Goal, Model)
    case dupGoal(Goal, Model)
    case viewGoal(Goal, Model)

    case switchToGoals(GoalsTableInvocationData)

    case createIcon(Model)
    case editIcon(Icon, Model)
    case pickIcon(Model)

    case createNote(Goal, Model)
    case editNote(Note, Model)

    case createAlarm(Model)
    case editAlarm(Alarm, Model)
    case dupAlarm(Alarm, Model)
    case viewAlarm(Alarm, Model)
    case scheduleAlarm(Alarm)
    case cancelAlarm(String)
    case setActiveAlarmCount(Int)

    case toggleSubscription

    case createEpoch(Model)

    case showDebugConsole
    case showEpochs
}

@MainActor
protocol DirectorInterface {
    /// Start a new usecase
    @discardableResult
    func request(_ request: DirectorRequest) async -> DirectorResult
    
    /// What tags are defined?
    var tags: [String] { get }

    /// Query the debug log
    var debugLogCache: LogCache { get }

    /// Save/Restore the home page index [state save empire goes here]
    var homePageIndex: Int { get set }
}

// MARK: - Concrete director class

@MainActor
class Director {
    enum Tab: Int {
        case home = 0
        case goals = 1
        case alarms = 2
        case notes = 3
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
                presenterFn: GoalsTablePresenter.init,
                image: UIImage(systemName: "list.bullet.rectangle")!.withBaselineOffset(fromBottom: 7)) {
                    [unowned self] goal in Task { await self.request(.viewGoal(goal!, model)) }
        }

        initTab(.alarms,
                queryResults: Alarm.sectionatedResultsSet(model: model),
                presenterFn: AlarmsTablePresenter.init) {
                    [unowned self] alarm in Task { await self.request(.viewAlarm(alarm!, model)) }
        }

        initTab(.notes,
                queryResults: Note.allSortedResultsSet(model: model),
                presenterFn: NotesTablePresenter.init,
                image: UIImage(systemName: "books.vertical.fill")!.withBaselineOffset(fromBottom: 5.5)) {
                    [unowned self] note in Task { await self.request(.editNote(note!, model)) }
        }

        initTab(.icons,
                queryResults: Icon.createAllResultsSet(model: model),
                presenterFn: IconsTablePresenter.init,
                image: UIImage(systemName: "photo.on.rectangle")!.withBaselineOffset(fromBottom: 7)) {
                    [unowned self] icon in Task { await self.request(.editIcon(icon!, model)) }
        }

        // Turn on the actual UI replacing the loading screen
        services.presentUI()
    }

    /// Helper to load + config the top-level table controllers
    private func initTab<ModelObjectType, PresenterType>(_ tab: Tab,
                                                         queryResults: ModelResultsSet,
                                                         presenterFn: MultiPresenterFn<DirectorInterface, ModelObjectType, PresenterType>,
                                                         image: UIImage? = nil,
                                                         picked: @escaping PresenterDone<ModelObjectType> = { _ in })
        where ModelObjectType: ModelObject,PresenterType: Presenter {
            services.initTab(tabIndex: tab.rawValue,
                             rootModel: rootModel!,
                             queryResults: queryResults,
                             presenterFn: presenterFn,
                             picked: picked)
        if let image = image {
            services.setTabImage(tab: tab.rawValue, image: image)
        }
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
    @MainActor
    func handle(director: Director, done: @escaping (DirectorResult) -> Void) {
        let services = director.services!
        let alarmScheduler = director.alarmScheduler

        switch self {
        case let .editGoal(goal, model):
            services.editThing("GoalEditViewController",
                               model: model,
                               object: goal,
                               presenterFn: GoalEditPresenter.init,
                               done: { _ in done(.none) })

        case let .dupGoal(goal, model):
            services.createThing("GoalEditViewController",
                                 model: model,
                                 from: goal,
                                 presenterFn: GoalEditPresenter.init,
                                 done: { _ in done(.none) })

        case let .viewGoal(goal, model):
            services.viewThing("GoalViewController",
                               model: model,
                               object: goal,
                               presenterFn: GoalViewPresenter.init)
            done(.none)

        case let .createGoal(model):
            services.createThing("GoalEditViewController",
                                 model: model,
                                 presenterFn: GoalEditPresenter.init,
                                 done: { _ in done(.none) })

        case let .switchToGoals(data):
            services.animateToTab(tabIndex: Director.Tab.goals.rawValue,
                                  invocationData: data as AnyObject)
            done(.none)

        case let .createIcon(model):
            services.createThing("IconEditViewController",
                                 model: model,
                                 presenterFn: IconEditPresenter.init,
                                 done: { done(.icon($0)) })

        case let .editIcon(icon, model):
            services.editThing("IconEditViewController",
                               model: model,
                               object: icon,
                               presenterFn: IconEditPresenter.init,
                               done: { _ in done(.none) })

        case let .pickIcon(model):
            services.pickThing("IconsTableViewController",
                               model: model,
                               results: Icon.createAllResults(model: model),
                               presenterFn: IconsTablePresenter.init,
                               done: { done(.icon($0)) })

        case let .editNote(note, model):
            services.editThing("NoteEditViewController",
                               model: model,
                               object: note,
                               presenterFn: NoteEditPresenter.init,
                               done: { _ in done(.none) })

        case let .createNote(goal, model):
            services.createThing("NoteEditViewController",
                                 model: model,
                                 presenterFn: NoteEditPresenter.init,
                                 done: { note in
                                     goal.add(note: note)
                                     done(.note(note))
                                 })

        case let .createAlarm(model):
            services.createThing("AlarmEditViewController",
                                 model: model,
                                 presenterFn: AlarmEditPresenter.init,
                                 done: { _ in done(.none) })
        case let .dupAlarm(alarm, model):
            services.createThing("AlarmEditViewController",
                                 model: model,
                                 from: alarm,
                                 presenterFn: AlarmEditPresenter.init,
                                 done: { _ in done(.none) })
        case let .editAlarm(alarm, model):
            services.editThing("AlarmEditViewController",
                               model: model,
                               object: alarm,
                               presenterFn: AlarmEditPresenter.init,
                               done: { _ in done(.none) })

        case let .viewAlarm(alarm, model):
            services.viewThing("AlarmViewController",
                               model: model,
                               object: alarm,
                               presenterFn: AlarmViewPresenter.init)
            done(.none)

        case let .scheduleAlarm(alarm):
            alarmScheduler.scheduleAlarm(text: alarm.notificationText,
                                         image: alarm.nativeImage,
                                         for: alarm.nextActiveDate) { uid in
                                            if let uid = uid {
                                                alarm.notificationUid = uid
                                            }
                                            done(.none)
                                         }

        case let .cancelAlarm(uid):
            alarmScheduler.cancelAlarm(uid: uid)
            done(.none)
        case let .setActiveAlarmCount(count):
            services.setTabBadge(tab: Director.Tab.alarms.rawValue, badge: (count == 0) ? nil : String(count))
            alarmScheduler.setActiveAlarmCount(count)
            done(.none)
        case .toggleSubscription:
            Prefs.subbed = !Prefs.subbed
            if Prefs.unsubbed {
                alarmScheduler.hideBadges()
            }
            done(.none)

        case let .createEpoch(model):
            services.createThing("EpochEditViewController",
                                 model: model,
                                 presenterFn: EpochEditPresenter.init,
                                 done: { _ in done(.none)})

        case .showDebugConsole:
            services.showNormally("DebugViewController",
                                  model: director.rootModel,
                                  presenterFn: DebugPresenter.init)
            done(.none)

        case .showEpochs:
            services.showModally("EpochsTableViewController",
                                 model: director.rootModel,
                                 presenterFn: EpochsTablePresenter.init,
                                 done: { done(.none) })
        }
    }
}

extension Director: DirectorInterface {
    /// Called from presenters to begin a new use-case
    @discardableResult
    func request(_ request: DirectorRequest) async -> DirectorResult {
        // We add a fibre break here to avoid very odd behaviours, eg.
        // multi-second delays on selecting a table row.
        // iOS15 async - it all seems OK now, suspect original issue was
        // an 'accidentally not on the main queue' problem now fixed by the
        // @MainActor enforcement stuff.
        await withCheckedContinuation { continuation in
            request.handle(director: self) {
                continuation.resume(returning: $0)
            }
        }
    }

    /// Call from presenter to query list of user-defined goal tags
    var tags: [String] {
        return tagList.tags
    }

    /// Debug log
    var debugLogCache: LogCache {
        logCache
    }
}
