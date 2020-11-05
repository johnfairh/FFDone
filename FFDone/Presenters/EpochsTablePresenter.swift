//
//  EpochsTablePresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Presenter inputs, commands, outputs
protocol EpochsTablePresenterInterface: TablePresenterInterface {
    func showDebug()
}

/// Epochs are pretty bare-bones, read-only presentational interface only
/// Actually a big hack to make this work modally - should go back and respec all the director view prez stuff

class EpochsTablePresenter: TablePresenter<DirectorInterface>, Presenter, EpochsTablePresenterInterface {
    typealias ViewInterfaceType = EpochsTablePresenter//Interface

    convenience init(director: DirectorInterface, model: Model, dismiss: @escaping () -> Void) {
        self.init(director: director,
                  model: model,
                  object: Epoch.createAllResultsSet(model: model),
                  mode: .multi(.manage),
                  dismiss: { _ in })
    }

    required init(director: DirectorInterface, model: Model, object: ModelResultsSet?, mode: PresenterMode, dismiss: @escaping PresenterDone<Epoch>) {
        super.init(director: director, model: model, object: object, mode: mode)
    }

    func createNewObject() {
        director.request(.createEpoch(model))
    }

    func showDebug() {
        director.request(.showDebugConsole)
    }
}
