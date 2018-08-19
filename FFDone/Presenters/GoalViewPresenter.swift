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

    /// Change the current steps value
    func setCurrentSteps(steps: Int)

    /// Let the user add a new note
    func addNote()

    /// Edit the goal
    func edit()

    /// Create a child presenter for the notes table
    func createNotesPresenter() -> GoalNotesTablePresenter
}

// MARK: - Presenter

/// This is a slightly odd view because it has some edit-y characteristics
/// but no explicit save button: changes made have to take effect + be saved
/// immediately.  We cheat a bit on the synchronization.
class GoalViewPresenter: Presenter, GoalViewPresenterInterface, GoalNotesTablePresenterDelegate {

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

    func setCurrentSteps(steps: Int) {
        let pinnedSteps = min(steps, goal.totalSteps)
        goal.currentSteps = pinnedSteps
        model.save()
        doRefresh()
    }

    /// Let the user add a new note
    func addNote() {
        director.request(.createNoteAndThen(goal, model, { [unowned self] _ in self.model.save() }))
    }

    /// Callback a note has been deleted from the table.
    func didDeleteNote() {
        model.save()
        doRefresh()
    }

    /// Edit this goal.
    func edit() {
        director.request(.editGoalAndThen(goal, model, { [unowned self] _ in self.doRefresh() }))
    }

    /// Create the notes table presenter
    func createNotesPresenter() -> GoalNotesTablePresenter {
        let presenter = GoalNotesTablePresenter(
            director: director,
            model: model,
            object: goal.notesResults(model: model),
            mode: .multi(.embed)) { note in self.director.request(.editNote(note!, self.model))}
        presenter.delegate = self
        return presenter
    }
}
