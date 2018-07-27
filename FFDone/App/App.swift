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

    private var modelProvider: ModelProvider
    private var director: Director
    private var directorServices: TabbedDirectorServices<DirectorInterface>

    init(window: UIWindow) {
        modelProvider = ModelProvider(userDbName: "DataModel")
        director = Director()
        directorServices = TabbedDirectorServices(director: director,
                                                  window: window,
                                                  tabBarVcName: "TabBarViewController")
        director.services = directorServices

        Log.log("App.init loading model and store")
        modelProvider.load(createFreshStore: true, initModelLoaded)
    }

    func initModelLoaded() {
        Log.log("App.init store loaded")
        guard let model = modelProvider.model else {
            Log.fatal("Model not available")
        }

        initRunOnceSetup(model: model)
        initDebugSampleObjects(model: model)

        model.save {
            self.initComplete(model: model)
        }
    }

    func initRunOnceSetup(model: Model) {
    }

    func initDebugSampleObjects(model: Model) {

        let goal = Goal.create(from: model)
        goal.name = "A goal"
        goal.sortOrder = 1
        goal.cdTotalSteps = 5
        goal.cdCurrentSteps = 2
    }

    func initComplete(model: Model) {
        Log.log("Init complete!")
        // write cookie
        director.modelIsReady(model: model)
    }
}
