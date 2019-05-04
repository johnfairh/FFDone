//
//  App.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Top-level container for app singletons.
///
/// Most of the code here is to do with the initialization dance.
final class App {

    #if targetEnvironment(simulator)
    static let debugMode = true
    #else
    static let debugMode = false
    #endif

    private let modelProvider: ModelProvider
    private let director: Director
    private let directorServices: TabbedDirectorServices<DirectorInterface>
    private let alarmScheduler: AlarmScheduler

    init(window: UIWindow, state: AppDelegate.ArchiveState) {
        if App.debugMode {
            Log.log("App launching **** IN DEBUG MODE **** RESETTING DATABASE ***")
            Prefs.runBefore = false
        }

        modelProvider = ModelProvider(userDbName: "DataModel")
        alarmScheduler = AlarmScheduler()
        director = Director(alarmScheduler: alarmScheduler, homePageIndex: state.homePageIndex)
        directorServices = TabbedDirectorServices(director: director,
                                                  window: window,
                                                  tabBarVcName: "TabBarViewController",
                                                  tabIndex: state.tabIndex)
        director.services = directorServices

        Log.enableDebugLogs = App.debugMode

        Log.log("App.init loading model and store")
        modelProvider.load(createFreshStore: App.debugMode, initModelLoaded)
    }

    func initModelLoaded() {
        Log.log("App.init store loaded")
        guard let model = modelProvider.model else {
            Log.fatal("Model not available")
        }

        if !Prefs.runBefore {
            DatabaseObjects.createOneTime(model: model, debugMode: App.debugMode)
        }
        DatabaseObjects.createEachTime(model: model, debugMode: App.debugMode)

        model.save {
            self.initComplete(model: model)
        }
    }

    func initComplete(model: Model) {
        Log.log("App.init complete!")
        Prefs.runBefore = true
        director.modelIsReady(model: model)
    }

    func willEnterForeground() {
        alarmScheduler.willEnterForeground()
    }

    var archiveState: AppDelegate.ArchiveState {
        return AppDelegate.ArchiveState(tabIndex: directorServices.currentTabIndex,
                                        homePageIndex: director.homePageIndex)
    }
    var currentTabIndex: Int {
        return directorServices.currentTabIndex
    }
    
    // MARK: Shared instance

    static var shared: App {
        return (UIApplication.shared.delegate as! AppDelegate).app
    }
}

/// Helper around app preferences
extension Prefs {
    static var runBefore: Bool {
        set {
            Prefs.set("RunBefore", to: newValue)
        }
        get {
            return Prefs.bool("RunBefore")
        }
    }

    static var defaultGoalIcon: String {
        set {
            Prefs.set("DefGoalIcon", to: newValue)
        }
        get {
            return Prefs.string("DefGoalIcon")
        }
    }

    static var defaultAlarmIcon: String {
        set {
            Prefs.set("DefAlarmIcon", to: newValue)
        }
        get {
            return Prefs.string("DefAlarmIcon")
        }
    }
}
