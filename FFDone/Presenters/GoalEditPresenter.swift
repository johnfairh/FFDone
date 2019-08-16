//
//  GoalEditPresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Presenter inputs, commands, outputs
protocol GoalEditPresenterInterface {

    /// Callback to refresh the view - goal, can save
    var refresh: (Goal, Bool) -> () { get set }

    /// Should view allow editting of 'current steps'?
    var canEditCurrentSteps: Bool { get }

    /// Various properties - will likely cause `refresh` reentrantly
    func setGoalName(name: String)
    func setCurrentSteps(steps: Int)
    func setTotalSteps(steps: Int)
    func setFav(fav: Bool)
    func setTag(tag: String?)

    /// Query current tags
    var tags: [String] { get }

    /// Let the user choose the icon
    func pickIcon()

    /// Let the user add a new note
    func addNote()

    /// Dismiss the view without committing and changes
    func cancel()

    /// Dismiss the view and save all changes
    func save()

    /// Create a child presenter for the notes table
    func createNotesPresenter() -> GoalNotesTablePresenter
}

// MARK: - Presenter

class GoalEditPresenter: EditablePresenter, GoalEditPresenterInterface, GoalNotesTablePresenterDelegate {

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
        refresh(goal, canSave)
    }

    /// For 'create' don't allow the current steps to be editted
    let canEditCurrentSteps: Bool

    required init(director: DirectorInterface,
                  model: Model,
                  object: Goal?,
                  mode: PresenterMode,
                  dismiss: @escaping PresenterDone<Goal>) {
        switch mode.singleType! {
        case .edit:
            goal = object!
            canEditCurrentSteps = true
        case .create:
            goal = Goal.createWithDefaults(model: model)
            canEditCurrentSteps = false
        case .dup:
            goal = object!.dup(model: model)
            canEditCurrentSteps = false
        default:
            Log.fatal("Bad mode: \(mode)")
        }

        self.model     = model
        self.director  = director
        self.dismissFn = dismiss
    }

    /// Validation
    var canSave: Bool {
        return goal.name != ""
    }

    var hasChanges: Bool {
        if !canEditCurrentSteps {
            return false
        }
        return goal.hasChanges
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

    func setTag(tag: String?) {
        goal.tag = tag
        doRefresh()
    }

    /// Query the defined tags for autocomplete
    var tags: [String] {
        return director.tags
    }

    /// Let the user choose the icon
    func pickIcon() {
        director.request(.pickIcon(model, { newIcon in
            self.goal.icon = newIcon
            self.doRefresh()
        }))
    }

    /// Let the user add a new note
    func addNote() {
        director.request(.createNote(goal, model))
    }

    /// Callback from nested presenter that a note has been deleted from the table.
    func didDeleteNote() {
        doRefresh()
    }

    func cancel() {
        dismissFn(nil)
    }

    func save() {
        model.save {
            self.dismissFn(self.goal)
        }
    }

    /// Create the notes table presenter
    func createNotesPresenter() -> GoalNotesTablePresenter {
        let presenter =  GoalNotesTablePresenter(
            director: director,
            model: model,
            object: goal.notesResults(model: model),
            mode: .multi(.embed)) { note in self.director.request(.editNote(note!, self.model))}
        presenter.delegate = self
        return presenter
    }
}
