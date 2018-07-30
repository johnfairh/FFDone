//
//  GoalEditPresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Presenter inputs, commands, outputs
protocol GoalEditPresenterInterface {
    /// Is the goal being editted actually being created now?
    /// (refactor?  used by view to decide what can be editted)
    var goalIsNew: Bool { get }

    /// Dismiss the view without committing and changes
    func cancel()

    /// Dismiss the view and save all changes
    func save()
}

// MARK: - Presenter

class GoalEditPresenter: Presenter, GoalEditPresenterInterface {

    typealias ViewInterfaceType = GoalEditPresenterInterface

    let goalIsNew: Bool

    private let goal: Goal
    private let model: Model
    private let director: DirectorInterface

    private let dismissFn: PresenterDone<Goal>

    required init(director: DirectorInterface,
                  model: Model,
                  object: Goal?,
                  mode: PresenterMode,
                  dismiss: @escaping PresenterDone<Goal>) {
        if let object = object {
            Log.assert(mode.isSingleType(.edit))
            goal = object
            goalIsNew = false
        } else {
            Log.assert(mode.isSingleType(.create))
            goal = Goal.createWithDefaults(model: model)
            goalIsNew = true
        }

        self.model     = model
        self.director  = director
        self.dismissFn = dismiss
    }

    func cancel() {
    }

    func save() {
    }
}
