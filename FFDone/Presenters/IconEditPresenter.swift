//
//  IconEditPresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Presenter inputs, commands, outputs

struct IconEditViewModel {
    let icon: Icon
    let isGoalDefault: Bool
    let isAlarmDefault: Bool
    let canSave: Bool
}

@MainActor
protocol IconEditPresenterInterface {
    /// Callback to refresh the view
    var refresh: (IconEditViewModel) -> () { get set }

    /// Change properties
    func setName(name: String)
    func setImage(image: UIImage)
    func clearImage()
    func setGoalDefault(value: Bool)
    func setAlarmDefault(value: Bool)

    /// Discard changes
    func cancel()

    /// Save the changes
    func save()
}

class IconEditPresenter: EditablePresenter, IconEditPresenterInterface {

    typealias ViewInterfaceType = IconEditPresenterInterface

    private let model: Model
    private let director: DirectorInterface
    private let dismissFn: PresenterDone<Icon>

    private let icon: Icon
    private var isGoalDefault: Bool
    private var isAlarmDefault: Bool

    public var hasChanges = false

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
        isGoalDefault = icon.isGoalDefault
        isAlarmDefault = icon.isAlarmDefault
    }

    var refresh: (IconEditViewModel) -> Void = { _ in } {
        didSet {
            doRefresh()
        }
    }

    private func modelUpdated() {
        hasChanges = true
        doRefresh()
    }

    private func doRefresh() {
        refresh(IconEditViewModel(icon: icon,
                                  isGoalDefault: isGoalDefault,
                                  isAlarmDefault: isAlarmDefault,
                                  canSave: canSave))
    }

    var canSave: Bool {
        icon.hasName && icon.hasImage
    }

    func setName(name: String) {
        icon.name = name
        modelUpdated()
    }

    func setImage(image: UIImage) {
        icon.nativeImage = image
        modelUpdated()
    }

    func clearImage() {
        icon.imageData = nil
        modelUpdated()
    }

    // we cheat a bit on this default

    func setGoalDefault(value: Bool) {
        isGoalDefault = value
        modelUpdated()
    }

    func setAlarmDefault(value: Bool) {
        isAlarmDefault = value
        modelUpdated()
    }

    /// Discard changes
    func cancel() {
        dismissFn(nil)
    }

    /// Save changes
    func save() {
        Log.assert(canSave)
        // These defaults aren't saved in core data so mess around a bit to sync them...
        model.save {
            self.icon.isGoalDefault = self.isGoalDefault
            self.icon.isAlarmDefault = self.isAlarmDefault
            self.dismissFn(self.icon)
        }
    }
}
