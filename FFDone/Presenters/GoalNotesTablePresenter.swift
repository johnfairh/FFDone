//
//  GoalNotesTablePresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation


/// This presenter is for the embedded notes table shared between goal-edit
/// and goal-view 'main' presenters.

/// Interface from the Notes Table VC to presenter -- requirements unique to notes table.
protocol GoalNotesTablePresenterInterface: TablePresenterInterface {
    func selectNote(_ note: Note)
    func deleteNote(_ note: Note)
}

/// Interface from the GoalNotes TablePresenter to its parent presenter
protocol GoalNotesTablePresenterDelegate: AnyObject {
    /// A note has been deleted - do whatever should be done.
    func didDeleteNote()
}

/// Minimal presenter for the embedded notes tableview
class GoalNotesTablePresenter: TablePresenter<DirectorInterface>, Presenter, GoalNotesTablePresenterInterface {
    typealias ViewInterfaceType = GoalNotesTablePresenter//Interface --- XXX weird swift generics vs. protocols runtime crash workaround XXX

    private let selectedCallback: PresenterDone<Note>
    weak var delegate: GoalNotesTablePresenterDelegate?

    required init(director: DirectorInterface, model: Model, object: ModelResultsSet?, mode: PresenterMode, dismiss: @escaping PresenterDone<Note>) {
        self.selectedCallback = dismiss
        super.init(director: director, model: model, object: object, mode: mode)
    }

    func selectNote(_ note: Note) {
        selectedCallback(note)
    }

    func deleteNote(_ note: Note) {
        note.delete(from: model)
        delegate?.didDeleteNote()
    }
}
