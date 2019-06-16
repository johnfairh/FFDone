//
//  AlarmViewPresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Presenter inputs, commands, outputs
protocol AlarmViewPresenterInterface {

    /// Callback to refresh the view
    var refresh: (Alarm) -> () { get set }

    /// Mark the alarm as complete
    func complete()

    /// Edit the notes
    func editNotes()

    /// Edit the alarm
    func edit()
}

// MARK: - Presenter

/// This is a slightly odd view because it has some edit-y characteristics
/// but no explicit save button: changes made have to take effect + be saved
/// immediately.  We cheat a bit on the synchronization.
class AlarmViewPresenter: Presenter, AlarmViewPresenterInterface {

    typealias ViewInterfaceType = AlarmViewPresenterInterface

    private let alarm: Alarm
    private let model: Model
    private let director: DirectorInterface
    private let dismissFn: PresenterDone<Alarm>

    var refresh: (Alarm) -> () = { _ in } {
        didSet {
            doRefresh()
        }
    }

    func doRefresh() {
        refresh(alarm)
    }

    required init(director: DirectorInterface,
                  model: Model,
                  object: Alarm?,
                  mode: PresenterMode,
                  dismiss: @escaping PresenterDone<Alarm>) {
        guard let object = object else {
            Log.fatal("Missing view object")
        }
        Log.assert(mode.isSingleType(.view))
        alarm = object

        self.model     = model
        self.director  = director
        self.dismissFn = dismiss
    }

    /// Mark the alarm as complete
    func complete() {
        if case .oneShot = alarm.kind {
            dismissFn(alarm)
            alarm.delete(from: model)
            model.save()
        } else {
            alarm.debugDeactivate()
            self.director.request(.scheduleAlarmAndThen(alarm, {
                self.model.save()
                self.doRefresh()
                self.dismissFn(self.alarm)
            }))
        }
    }

    /// Edit the notes
    func editNotes() {
        guard let note = alarm.activeNote else {
            Log.fatal("Missing active note for alarm \(alarm)")
        }
        director.request(.editNoteAndThen(note, model, { _ in
            self.model.save()
            self.doRefresh()
        }))
    }

    /// Edit the alarm
    func edit() {
        director.request(.editAlarmAndThen(alarm, model, { [unowned self] _ in self.doRefresh() }))
    }
}
