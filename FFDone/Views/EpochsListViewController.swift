//
//  EpochsListViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

class EpochsListViewController: PresentableBasicCollectionVC<EpochsListPresenterInterface> {
    @IBAction func addButtonTapped(_ sender: Any) {
        presenter.addEpoch()
    }
}
