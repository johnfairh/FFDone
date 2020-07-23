//
//  EpochsListViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

class EpochsListViewController: PresentableBasicCollectionVC<EpochsListPresenterInterface> {
    @IBAction func debugButtonTapped(_ sender: UIBarButtonItem) {
        presenter.showDebug()
    }

    @IBAction func addButtonTapped(_ sender: Any) {
        presenter.addEpoch()
    }
}
