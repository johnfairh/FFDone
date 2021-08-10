//
//  EpochsTablePresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Presenter inputs, commands, outputs
@MainActor
protocol EpochsTablePresenterInterface: TablePresenterInterface {
    func showDebug()
    func swipeActionFor(epoch: Epoch) -> TableSwipeAction?
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
        Task { await director.request(.createEpoch(model)) }
    }

    func showDebug() {
        Task { await director.request(.showDebugConsole) }
    }

    func swipeActionFor(epoch: Epoch) -> TableSwipeAction? {
        guard !epoch.isGlobal else {
            return nil
        }

        let major = epoch.majorVersion

        return TableSwipeAction(text: "Merge \(major).X", color: .tableLeadingSwipe, action: {
            Epoch.merge(major: major, in: self.model)
            self.model.save()
        })
    }
}
