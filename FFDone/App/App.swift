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

    private var modelProvider: ModelProvider
    private var director: Director
    private var directorServices: TabbedDirectorServices<DirectorInterface>
    private let tagManager: TagManager

    init(window: UIWindow) {
        if App.debugMode {
            Log.log("App launching **** IN DEBUG MODE **** RESETTING DATABASE ***")
            Prefs.runBefore = false
        }

        modelProvider = ModelProvider(userDbName: "DataModel")
        tagManager = TagManager(provider: modelProvider)
        director = Director()
        directorServices = TabbedDirectorServices(director: director,
                                                  window: window,
                                                  tabBarVcName: "TabBarViewController")
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
        tagManager.start()
        Prefs.runBefore = true
        director.modelIsReady(model: model)
    }

    // MARK: Tag List

    class TagManager: ModelFieldWatcherDelegate {
        var tags: [String]
        var runner: ModelFieldWatcher

        init(provider: ModelProvider) {
            tags = []
            runner = ModelFieldWatcher(modelProvider: provider,
                                       fetchRequest: Goal.tagListFieldFetchRequest)
        }

        func start() {
            runner.delegate = self
        }

        func updateQueryResults(results: ModelFieldResults) {
            tags = results.compactMap { $0.values.first as? String }
        }
    }

    var tags: [String] { // get rid of this, should come to views via presenter -> director-req
        return tagManager.tags
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
}
