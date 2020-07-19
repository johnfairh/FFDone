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
    static let debugMode = false
    #else
    static let debugMode = false
    #endif

    // App-wide shared stuff that we own
    private let modelProvider: ModelProvider

    // App-wide shared stuff that we publish
    private(set) var alarmScheduler: AlarmScheduler!
    private(set) var tagList: TagList!
    private(set) var logCache: LogCache

    /// Model-Ready synchronization
    typealias AppReadyCallback = (Model) -> Void

    private var appReadyWaitList: [AppReadyCallback] = []

    func notifyWhenReady(_ callback: @escaping AppReadyCallback) {
        if appIsReady {
            Dispatch.toForeground {
                callback(self.modelProvider.model)
            }
        } else {
            appReadyWaitList.append(callback)
        }
    }

    // Perfect for a publisher!
    private var appIsReady = false {
        didSet {
            guard appIsReady else { return }
            while let next = appReadyWaitList.popLast() {
                Dispatch.toForeground {
                    next(self.modelProvider.model)
                }
            }
        }
    }

    init() {
        if App.debugMode {
            Log.log("App launching **** IN DEBUG MODE **** RESETTING DATABASE ***")
            Prefs.runBefore = false
        }

        modelProvider = ModelProvider(userDbName: "DataModel")
        logCache = LogCache()
        alarmScheduler = AlarmScheduler(app: self)
        tagList = TagList(app: self)
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
        appIsReady = true
    }

    func willEnterForeground() {
        Log.log("App.willEnterForeground")
        alarmScheduler.willEnterForeground()
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
