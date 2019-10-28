//
//  AlarmEditPresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Presenter inputs, commands, outputs
protocol AlarmEditPresenterInterface {
    /// Callback to refresh the view
    var refresh: (Alarm, Bool) -> () { get set }

    /// Properties - will likely cause `refresh` reentrantly
    func setName(name: String)
    func setKind(kind: Alarm.Kind)

    /// Let the user choose the icon
    func pickIcon()

    /// Let the user edit the active notes
    func editActiveNotes()

    /// Let the user edit the default notes
    func editDefaultNotes()

    /// Dismiss the view without committing and changes
    func cancel()

    /// Dismiss the view and save all changes
    func save()
}

// MARK: - Presenter

class AlarmEditPresenter: EditablePresenter, AlarmEditPresenterInterface {

    typealias ViewInterfaceType = AlarmEditPresenterInterface

    private let alarm: Alarm
    private let model: Model
    private let director: DirectorInterface
    private let dismissFn: PresenterDone<Alarm>

    var refresh: (Alarm, Bool) -> () = { _, _ in } {
        didSet {
            doRefresh()
        }
    }

    func doRefresh() {
        refresh(alarm, canSave)
    }

    required init(director: DirectorInterface,
                  model: Model,
                  object: Alarm?,
                  mode: PresenterMode,
                  dismiss: @escaping PresenterDone<Alarm>) {
        if let object = object {
            Log.assert(mode.isSingleType(.edit))
            alarm = object
        } else {
            Log.assert(mode.isSingleType(.create))
            alarm = Alarm.createWithDefaults(model: model)
        }

        self.model     = model
        self.director  = director
        self.dismissFn = dismiss
    }

    /// Validation
    var canSave: Bool {
        alarm.text != ""
    }

    var hasChanges: Bool {
        !alarm.isInserted && alarm.hasChanges
    }

    func setName(name: String) {
        alarm.name = name
        doRefresh()
    }

    func setKind(kind: Alarm.Kind) {
        alarm.kind = kind
        doRefresh()
    }

    /// Let the user choose the icon
    func pickIcon() {
        director.request(.pickIcon(model, { newIcon in
            self.alarm.icon = newIcon
            self.doRefresh()
        }))
    }

    /// Let the user edit the active notes
    func editActiveNotes() {
        guard let note = alarm.activeNote else {
            Log.fatal("Missing active note for alarm \(alarm)")
        }
        director.request(.editNoteAndThen(note, model, { _ in self.doRefresh() }))
    }

    /// Let the user edit the default notes
    func editDefaultNotes() {
        guard let note = alarm.defaultNote else {
            Log.fatal("Missing default note for alarm \(alarm)")
        }
        director.request(.editNote(note, model))
    }

    func cancel() {
        dismissFn(nil)
    }

    func save() {
        model.save {
            self.dismissFn(self.alarm)
        }
    }
}

