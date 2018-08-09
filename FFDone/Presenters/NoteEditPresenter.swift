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

    /// Discard changes
    func cancel()

    /// Save the changes and close the sessions
    func save(text: String)
}

class NoteEditPresenter: Presenter, NoteEditPresenterInterface {

    typealias ViewInterfaceType = NoteEditPresenterInterface

    private let note: Note
    private let model: Model
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
        self.dismissFn = dismiss
    }

    var text: String {
        return note.text ?? ""
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
