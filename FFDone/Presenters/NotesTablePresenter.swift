//
//  NotesTablePresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Interface from the Icons Table VC to presenter -- requirements unique to icons table.
protocol NotesTablePresenterInterface: TablePresenterInterface {
    func selectNote(_ note: Note)
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
}
