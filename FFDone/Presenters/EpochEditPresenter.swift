//
//  EpochEditPresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Presenter inputs, commands, outputs
protocol EpochEditPresenterInterface {
    /// Callback to refresh the view
    var refresh: (Epoch, Bool) -> () { get set }

    /// Properties - will likely cause `refresh` reentrantly
    func set(shortName: String)
    func set(longName: String)
    func set(versionString: String)

    /// Dismiss the view without committing and changes
    func cancel()

    /// Dismiss the view and save all changes
    func save()
}

// MARK: - Presenter

class EpochEditPresenter: EditablePresenter, EpochEditPresenterInterface {

    typealias ViewInterfaceType = EpochEditPresenterInterface

    private let previousEpoch: Epoch
    private let epoch: Epoch
    private let model: Model
    private let director: DirectorInterface
    private let dismissFn: PresenterDone<Epoch>

    public var hasChanges = false

    var refresh: (Epoch, Bool) -> () = { _, _ in } {
        didSet {
            refresh(epoch, canSave)
        }
    }

    func doRefresh() {
        hasChanges = true
        refresh(epoch, canSave)
    }

    required init(director: DirectorInterface,
                  model: Model,
                  object: Epoch?,
                  mode: PresenterMode,
                  dismiss: @escaping PresenterDone<Epoch>) {
        Log.assert(mode.isSingleType(.create))
        Log.assert(object == nil)
        self.previousEpoch = Epoch.mostRecent(in: model)
        self.epoch     = Epoch.createFrom(previous: previousEpoch, in: model)
        self.model     = model
        self.director  = director
        self.dismissFn = dismiss
    }

    /// Validation
    var canSave: Bool {
        epoch.canSave
    }

    /// Setters
    func set(shortName: String) {
        epoch.shortName = shortName
        doRefresh()
    }

    func set(longName: String) {
        epoch.longName = longName
        doRefresh()
    }

    func set(versionString: String) {
        if epoch.parse(version: versionString) {
            doRefresh()
        }
    }

    func cancel() {
        dismissFn(nil)
    }

    func save() {
        if !previousEpoch.isGlobal {
            previousEpoch.endDate = epoch.startDate
        }
        model.save {
            self.dismissFn(self.epoch)
        }
    }
}
