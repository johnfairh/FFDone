//
//  IconEditPresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Presenter inputs, commands, outputs
protocol IconEditPresenterInterface {

    /// Callback to refresh the view
    var refresh: (Icon, Bool) -> () { get set }

    /// Change properties
    func setName(name: String)
    func setImage(image: UIImage)
    func clearImage()

    /// Discard changes
    func cancel()

    /// Save the changes
    func save()
}

class IconEditPresenter: Presenter, IconEditPresenterInterface {

    typealias ViewInterfaceType = IconEditPresenterInterface

    private let model: Model
    private let director: DirectorInterface
    private let dismissFn: PresenterDone<Icon>
    private let icon: Icon

    required init(director: DirectorInterface,
                  model: Model,
                  object: Icon?,
                  mode: PresenterMode,
                  dismiss: @escaping PresenterDone<Icon>) {
        if let icon = object {
            Log.assert(mode.isSingleType(.edit))
            self.icon = icon
        } else {
            Log.assert(mode.isSingleType(.create))
            self.icon = Icon.createWithDefaults(model: model)
        }
        self.model     = model
        self.director  = director
        self.dismissFn = dismiss
    }

    var refresh: (Icon, Bool) -> Void = { _, _ in } {
        didSet {
            doRefresh()
        }
    }

    private func doRefresh() {
        refresh(icon, isSaveAllowed)
    }

    private var isSaveAllowed: Bool {
        return icon.hasName && icon.hasImage
    }

    func setName(name: String) {
        icon.name = name
        doRefresh()
    }

    func setImage(image: UIImage) {
        icon.nativeImage = image
        doRefresh()
    }

    func clearImage() {
        icon.imageData = nil
        doRefresh()
    }

    /// Discard changes
    func cancel() {
        dismissFn(nil)
    }

    /// Save changes
    func save() {
        Log.assert(isSaveAllowed)
        model.save {
            self.dismissFn(self.icon)
        }
    }
}
