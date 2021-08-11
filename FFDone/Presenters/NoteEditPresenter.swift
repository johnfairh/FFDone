//
//  NoteEditPresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Presenter inputs, commands, outputs
@MainActor
protocol NoteEditPresenterInterface {
    /// Initial text to edit
    var text: String { get set }

    /// Date of the note
    var date: String { get }

    /// Name of note's owner, if any
    var ownerName: String? { get }

    /// Icon of note's owner, if any
    var ownerIcon: Icon? { get }

    /// Go display the owner
    func showOwner()

    /// Discard changes
    func cancel()

    /// Save the changes and close the session
    func save()
}

class NoteEditPresenter: EditablePresenter, NoteEditPresenterInterface {

    typealias ViewInterfaceType = NoteEditPresenterInterface

    private let note: Note
    private let model: Model
    private let director: DirectorInterface
    private let dismissFn: PresenterDone<Note>

    public let canSave = true
    public var hasChanges = false

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
        get {
            note.text ?? ""
        }
        set {
            note.text = newValue
            hasChanges = true
        }
    }

    var date: String {
        return Note.dayStampToUserString(dayStamp: note.dayStamp!)
    }

    // MARK: - Owner stuff

    /// Name of note's owner
    private var owner: (String?, Icon?) {
        if let goal = note.goal {
            return (note.extendedGoalTitle, goal.icon)
        } else if let alarm = note.activeAlarm {
            return (alarm.name, alarm.icon)
        } else if let alarm = note.defaultAlarm {
            return (alarm.name, alarm.icon)
        }
        return (nil, nil)
    }


    /// Name of note's owner
    var ownerName: String? {
        return owner.0
    }

    /// Icon of note's owner, if any
    var ownerIcon: Icon? {
        return owner.1
    }

    func showOwner() {
        if let goal = note.goal {
            director.request(.viewGoal(goal, model))
        }
        // choosing to do nothing for alarms, can only make loops....
    }
    
    func cancel() {
        dismissFn(nil)
    }

    func save() {
        model.save {
            self.dismissFn(self.note)
        }
    }
}
