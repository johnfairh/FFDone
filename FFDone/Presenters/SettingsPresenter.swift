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

    /// Dismiss settings
    func close()
}

class SettingsPresenter: Presenter, SettingsPresenterInterface {
    typealias ViewInterfaceType = SettingsPresenterInterface

    private let model: Model
    private let director: DirectorInterface
    private let dismiss: PresenterDone<Epoch>

    // tmp model
    private var epochsEnabled = false
    private var epochDate = Date()

    convenience init(director: DirectorInterface, model: Model, dismiss: @escaping () -> Void) {
        self.init(director: director, model: model,
                  object: nil, mode: .single(.create),
                  dismiss: { _ in dismiss() })
    }

    required init(director: DirectorInterface, model: Model, object: ModelResultsSet?, mode: PresenterMode, dismiss: @escaping PresenterDone<Epoch>) {
        self.model = model
        self.director = director
        self.dismiss = dismiss
    }

    var refresh: (Bool, Date) -> Void = { _, _ in } {
        didSet {
            doRefresh()
        }
    }

    func doRefresh() {
        refresh(epochsEnabled, epochDate)
    }

    /// Enable/disable multiple epochs
    func enableEpochs(_ flag: Bool) {
        epochsEnabled = flag
        doRefresh()
    }

    /// Set the epoch date
    func setEpochDate(_ date: Date) {
        epochDate = date
        doRefresh()
    }

    /// Request debug window
    func showDebug() {
        director.request(.showDebugConsole)
    }

    func close() {
        dismiss(nil)
    }
}
