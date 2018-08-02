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

    static let debugMode = true

    private var modelProvider: ModelProvider
    private var director: Director
    private var directorServices: TabbedDirectorServices<DirectorInterface>

    init(window: UIWindow) {
        if App.debugMode {
            Log.log("App launching **** IN DEBUG MODE **** RESETTING DATABASE ***")
            Prefs.runBefore = false
        }

        modelProvider = ModelProvider(userDbName: "DataModel")
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
            DatabaseObjects.create(model: model, debugMode: App.debugMode)
        }

        model.save {
            self.initComplete(model: model)
        }
    }

    func initComplete(model: Model) {
        Log.log("Init complete!")
        Prefs.runBefore = true
        director.modelIsReady(model: model)
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
