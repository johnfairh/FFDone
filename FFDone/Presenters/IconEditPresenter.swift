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
    let hasChanges: Bool
}
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

class IconEditPresenter: Presenter, IconEditPresenterInterface {

    typealias ViewInterfaceType = IconEditPresenterInterface

    private let model: Model
    private let director: DirectorInterface
    private let dismissFn: PresenterDone<Icon>

    private let icon: Icon
    private var isGoalDefault: Bool
    private var isAlarmDefault: Bool

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

    private func doRefresh() {
        refresh(IconEditViewModel(icon: icon,
                                  isGoalDefault: isGoalDefault,
                                  isAlarmDefault: isAlarmDefault,
                                  canSave: isSaveAllowed,
                                  hasChanges: !icon.isInserted && icon.hasChanges))
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

    // we cheat a bit on this default

    func setGoalDefault(value: Bool) {
        isGoalDefault = value
        doRefresh()
    }

    func setAlarmDefault(value: Bool) {
        isAlarmDefault = value
        doRefresh()
    }

    /// Discard changes
    func cancel() {
        dismissFn(nil)
    }

    /// Save changes
    func save() {
        Log.assert(isSaveAllowed)
        // These defaults aren't saved in core data so mess around a bit to sync them...
        model.save {
            self.icon.isGoalDefault = self.isGoalDefault
            self.icon.isAlarmDefault = self.isAlarmDefault
            self.dismissFn(self.icon)
        }
    }
}
