//
//  GoalEditPresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Presenter inputs, commands, outputs
protocol GoalEditPresenterInterface {

    /// Callback to refresh the view
    var refresh: (Goal, Bool) -> () { get set }

    /// Should view allow editting of 'current steps'?
    var canEditCurrentSteps: Bool { get }

    /// Various properties - will likely cause `refresh` reentrantly
    func setGoalName(name: String)
    func setCurrentSteps(steps: Int)
    func setTotalSteps(steps: Int)
    func setFav(fav: Bool)

    /// Let the user choose the icon
    func pickIcon()

    /// Dismiss the view without committing and changes
    func cancel()

    /// Dismiss the view and save all changes
    func save()
}

// MARK: - Presenter

class GoalEditPresenter: Presenter, GoalEditPresenterInterface {

    typealias ViewInterfaceType = GoalEditPresenterInterface

    private let goal: Goal
    private let model: Model
    private let director: DirectorInterface
    private let dismissFn: PresenterDone<Goal>

    var refresh: (Goal, Bool) -> () = { _, _ in } {
        didSet {
            doRefresh()
        }
    }

    func doRefresh() {
        refresh(goal, isSaveAllowed)
    }

    /// For 'create' don't allow the current steps to be editted
    let canEditCurrentSteps: Bool

    required init(director: DirectorInterface,
                  model: Model,
                  object: Goal?,
                  mode: PresenterMode,
                  dismiss: @escaping PresenterDone<Goal>) {
        if let object = object {
            Log.assert(mode.isSingleType(.edit))
            goal = object
            canEditCurrentSteps = true
        } else {
            Log.assert(mode.isSingleType(.create))
            goal = Goal.createWithDefaults(model: model)
            canEditCurrentSteps = false
        }

        self.model     = model
        self.director  = director
        self.dismissFn = dismiss
    }

    /// Validation
    var isSaveAllowed: Bool {
        return goal.name != ""
    }

    func setGoalName(name: String) {
        goal.name = name
        doRefresh()
    }

    func setCurrentSteps(steps: Int) {
        goal.currentSteps = steps
        if goal.totalSteps < goal.currentSteps {
            goal.totalSteps = goal.currentSteps
        }
        doRefresh()
    }

    func setTotalSteps(steps: Int) {
        goal.totalSteps = steps
        if goal.totalSteps < goal.currentSteps {
            goal.currentSteps = goal.totalSteps
        }
        doRefresh()
    }

    func setFav(fav: Bool) {
        goal.isFav = fav
        doRefresh()
    }

    /// Let the user choose the icon
    func pickIcon() {
        director.request(.pickIcon(model, { newIcon in
            self.goal.icon = newIcon
            self.doRefresh()
        }))
    }

    func cancel() {
        dismissFn(nil)
    }

    func save() {
        model.save {
            self.dismissFn(self.goal)
        }
    }
}
