//
//  EpochsListPresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Presenter inputs, commands, outputs
protocol EpochsListPresenterInterface {
    func addEpoch()
    func showDebug()
}

class EpochsListPresenter: Presenter, EpochsListPresenterInterface {
    typealias ViewInterfaceType = EpochsListPresenterInterface

    private let model: Model
    private let director: DirectorInterface

    convenience init(director: DirectorInterface, model: Model, dismiss: @escaping () -> Void) {
        self.init(director: director, model: model,
                  object: nil, mode: .single(.create),
                  dismiss: { _ in dismiss() })
    }

    required init(director: DirectorInterface, model: Model, object: ModelResultsSet?, mode: PresenterMode, dismiss: @escaping PresenterDone<Goal>) {
        self.model = model
        self.director = director
    }

    func addEpoch() {
        director.request(.createEpoch(model))
    }

    func showDebug() {
        director.request(.showDebugConsole)
    }
}
