//
//  NoteEditPresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Presenter inputs, commands, outputs
protocol NoteEditPresenterInterface {

    /// Initial text to edit
    var text: String { get }

    /// Date of the note
    var date: String { get }

    /// Goal associated with the note, if any
    var goal: Goal? { get }

    /// Go display the goal
    func showGoal()

    /// Discard changes
    func cancel()

    /// Save the changes and close the session
    func save(text: String)
}

class NoteEditPresenter: Presenter, NoteEditPresenterInterface {

    typealias ViewInterfaceType = NoteEditPresenterInterface

    private let note: Note
    private let model: Model
    private let director: DirectorInterface
    private let dismissFn: PresenterDone<Note>

    required init(director: DirectorInterface,
                  model: Model,
                  object: Note?,
                  mode: PresenterMode,
                  dismiss: @escaping PresenterDone<Note>) {
        if let note = object {
            Log.assert(mode.isSingleType(.edit))
            self.note = note
        } else {
            Log.assert(mode.isSingleType(.create))
            self.note = Note.createWithDefaults(model: model)
        }
        self.model     = model
        self.director  = director
        self.dismissFn = dismiss
    }

    var text: String {
        return note.text ?? ""
    }

    var date: String {
        return Note.dayStampToUserString(dayStamp: note.dayStamp!)
    }

    var goal: Goal? {
        return note.goal
    }

    func showGoal() {
        if let goal = note.goal {
            director.request(.viewGoal(goal, model))
        }
    }
    
    func cancel() {
        dismissFn(nil)
    }

    func save(text: String) {
        note.text = text
        model.save {
            self.dismissFn(self.note)
        }
    }
}
