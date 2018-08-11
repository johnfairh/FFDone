//
//  IconEditPresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Presenter inputs, commands, outputs
protocol IconEditPresenterInterface {

    /// Discard changes
    func cancel()

    /// Create a new Icon
    func save(name: String, image: UIImage)
}

class IconEditPresenter: Presenter, IconEditPresenterInterface {

    typealias ViewInterfaceType = IconEditPresenterInterface

    private let model: Model
    private let director: DirectorInterface
    private let dismissFn: PresenterDone<Icon>

    required init(director: DirectorInterface,
                  model: Model,
                  object: Icon?,
                  mode: PresenterMode,
                  dismiss: @escaping PresenterDone<Icon>) {
        Log.assert(object == nil && mode.isSingleType(.create))
        self.model     = model
        self.director  = director
        self.dismissFn = dismiss
    }

    /// Discard changes
    func cancel() {
        dismissFn(nil)
    }

    /// Create a new Icon
    func save(name: String, image: UIImage) {
        let icon = Icon.create(from: model)
        icon.isBuiltin = false
        icon.isDefault = false
        icon.name = name
        icon.nativeImage = image
        icon.sortOrder = Icon.getNextSortOrderValue(Icon.primarySortOrder, from: model)
        model.save {
            self.dismissFn(icon)
        }
    }
}
