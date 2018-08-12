//
//  GoalViewPresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Presenter inputs, commands, outputs
protocol GoalViewPresenterInterface {

    /// Callback to refresh the view
    var refresh: (Goal) -> () { get set }

    func addStep()

    /// Let the user add a new note
    func addNote()

    /// Edit the goal
    func edit()

    /// Create a child presenter for the notes table
    func createNotesPresenter() -> GoalNotesTablePresenter
}

// MARK: - Presenter

class GoalViewPresenter: Presenter, GoalViewPresenterInterface {

    typealias ViewInterfaceType = GoalViewPresenterInterface

    private let goal: Goal
    private let model: Model
    private let director: DirectorInterface
    private let dismissFn: PresenterDone<Goal>

    var refresh: (Goal) -> () = { _ in } {
        didSet {
            doRefresh()
        }
    }

    func doRefresh() {
        refresh(goal)
    }

    required init(director: DirectorInterface,
                  model: Model,
                  object: Goal?,
                  mode: PresenterMode,
                  dismiss: @escaping PresenterDone<Goal>) {
        guard let object = object else {
            Log.fatal("Missing view object")
        }
        Log.assert(mode.isSingleType(.view))
        goal = object

        self.model     = model
        self.director  = director
        self.dismissFn = dismiss
    }

    func addStep() {
    }

    /// Let the user add a new note
    func addNote() {
        director.request(.createNote(goal, model))
    }

    func edit() {
        director.request(.editGoal(goal, model)) // XXX and refresh self
    }

    /// Create the notes table presenter
    func createNotesPresenter() -> GoalNotesTablePresenter {
        return GoalNotesTablePresenter(
            director: director,
            model: model,
            object: goal.notesResults(model: model),
            mode: .multi(.embed)) { note in self.director.request(.editNote(note!, self.model))}
    }
}
