//
//  HomePresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Presenter inputs, commands, outputs
protocol HomePresenterInterface {
}

class HomePresenter: Presenter, HomePresenterInterface {

    typealias ViewInterfaceType = HomePresenterInterface

    private let query: ModelResultsSet
    private let model: Model
    private let director: DirectorInterface

    required init(director: DirectorInterface, model: Model, object: ModelResultsSet?, mode: PresenterMode, dismiss: @escaping PresenterDone<Goal>) {
        Log.assert(mode.isMultiType(.manage) && object != nil)
        self.query    = object!
        self.model    = model
        self.director = director
    }
}
