//
//  SettingsPresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Presenter inputs, commands, outputs
protocol SettingsPresenterInterface {
    /// Get told about data changes
    var refresh: (Bool, Date) -> Void { get set }

    /// Enable/disable multiple epochs
    func enableEpochs(_ flag: Bool)

    /// Set the epoch date
    func setEpochDate(_ date: Date)

    /// Request debug window
    func showDebug()

    /// Request epochs list
    func showEpochs()

    /// Dismiss settings
    func close()
}

class SettingsPresenter: Presenter, SettingsPresenterInterface {
    typealias ViewInterfaceType = SettingsPresenterInterface

    private let model: Model
    private let director: DirectorInterface
    private let dismiss: PresenterDone<Epoch>

    // model
    private let epochResults: ModelResults
    private var epochWatcher: ModelResultsWatcher<Epoch>?

    convenience init(director: DirectorInterface, model: Model, dismiss: @escaping () -> Void) {
        self.init(director: director, model: model,
                  object: nil, mode: .single(.create),
                  dismiss: { _ in dismiss() })
    }

    required init(director: DirectorInterface, model: Model, object: ModelResultsSet?, mode: PresenterMode, dismiss: @escaping PresenterDone<Epoch>) {
        self.model = model
        self.director = director
        self.dismiss = dismiss

        epochResults = Epoch.createAllResults(model: model)
        epochResults.issueFetch()
    }

    var refresh: (Bool, Date) -> Void = { _, _ in } {
        didSet {
            epochWatcher = ModelResultsWatcher(modelResults: epochResults) { [weak self] _ in
                self?.doRefresh()
            }
            doRefresh()
        }
    }

    private var secondEpoch: Epoch? {
        guard let epochs = epochResults.fetchedObjects as? [Epoch],
            epochs.count > 1 else {
                return nil
        }
        return epochs[1]
    }

    func doRefresh() {
        let epoch = secondEpoch
        let epochDate = epoch?.startDate ?? Date()
        refresh(epoch != nil, epochDate)
    }

    /// Enable/disable multiple epochs
    func enableEpochs(_ flag: Bool) {
        if flag {
            let epoch = Epoch.createWithDefaults(model: model)
            Log.assert(epoch.sortOrder == 2)
        } else {
            secondEpoch!.delete(from: model)
        }
        model.save() // -> doRefresh via watcher
    }

    /// Set the epoch date
    func setEpochDate(_ date: Date) {
        secondEpoch!.startDate = date
        model.save() // -> doRefresh via watcher
    }

    /// Request debug window
    func showDebug() {
        director.request(.showDebugConsole)
    }

    func showEpochs() {
        director.request(.showEpochs)
    }

    func close() {
        dismiss(nil)
    }
}
