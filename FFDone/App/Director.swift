//
//  Director.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

enum DirectorRequest {
    case editGoal(Goal, Model)
    case editGoalAndThen(Goal, Model, (Goal) -> Void)
}

protocol DirectorInterface {
    func request(_ request: DirectorRequest)
}

class Director {

    weak var services: TabbedDirectorServices<DirectorInterface>!
    private var rootModel: Model!

    init() {
    }

    func modelIsReady(model: Model) {
        rootModel = model

        Log.log("Director.modelIsReady")

        // set tabs

        // Turn on the actual UI replacing the loading screen
        services.presentUI()
    }
}

extension Director: DirectorInterface {

    func request(_ request: DirectorRequest) {
        switch request {
        case let .editGoal(goal, model):
            Log.fatal("No idea how to edit a goal \(goal) \(model)")

        case let .editGoalAndThen(goal, model, continuation):
            Log.fatal("Still no idea how to edit a goal \(goal) \(model) \(continuation)")
        }
    }
}
