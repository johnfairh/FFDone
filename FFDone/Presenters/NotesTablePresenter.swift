//
//  NotesTablePresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Interface from the Notes Table VC to presenter -- requirements unique to notes table.
protocol NotesTablePresenterInterface: TablePresenterInterface {
    func selectNote(_ note: Note)
    func updateSearchResults(text: String)
    func deleteNote(_ note: Note)
}

// MARK: - Presenter

class NotesTablePresenter: TablePresenter<DirectorInterface>, Presenter, NotesTablePresenterInterface {
    typealias ViewInterfaceType = NotesTablePresenter//Interface --- XXX weird swift generics vs. protocols runtime crash workaround XXX

    private let selectedCallback: PresenterDone<Note>

    required init(director: DirectorInterface, model: Model, object: ModelResultsSet?, mode: PresenterMode, dismiss: @escaping PresenterDone<Note>) {
        self.selectedCallback = dismiss
        super.init(director: director, model: model, object: object, mode: mode)
    }

    func selectNote(_ note: Note) {
        selectedCallback(note)
    }

    func deleteNote(_ note: Note) {
        note.delete(from: model)
        model.save()
    }

    // MARK: - Search

    func updateSearchResults(text: String) {
        handleSearchUpdate(text: text, type: 0) { text, typeInt in
            return Note.searchByTextSortedResultsSet(model: self.model, str: text)
        }
    }
}
