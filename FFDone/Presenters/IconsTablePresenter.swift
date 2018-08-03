//
//  IconsTablePresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Interface from the Icons Table VC to presenter -- requirements unique to icons table.
protocol IconsTablePresenterInterface: TablePresenterInterface {
    func canDeleteIcon(_ icon: Icon) -> Bool
    func deleteIcon(_ icon: Icon)
    func canMoveIcon(_ icon: Icon) -> Bool
    func moveIcon(_ icon: Icon, fromRow: Int, toRow: Int)
    func selectIcon(_ icon: Icon)
}

// MARK: - Presenter

class IconsTablePresenter: TablePresenter<DirectorInterface>, Presenter, IconsTablePresenterInterface {
    typealias ViewInterfaceType = IconsTablePresenter//Interface --- XXX weird swift generics vs. protocols runtime crash workaround XXX

    private let selectedCallback: PresenterDone<Icon>

    required init(director: DirectorInterface, model: Model, object: ModelResultsSet?, mode: PresenterMode, dismiss: @escaping PresenterDone<Icon>) {
        self.selectedCallback = dismiss
        super.init(director: director, model: model, object: object, mode: mode)
    }

    func createNewObject() {
        Log.log("CREATE NEW ICON")
    }

    func canDeleteIcon(_ icon: Icon) -> Bool {
        return isEditable && !icon.isBuiltin && icon.usingGoals?.count == 0
    }

    func deleteIcon(_ icon: Icon) {
        icon.delete(from: model)
        model.save()
    }

    func canMoveIcon(_ icon: Icon) -> Bool {
        return isEditable
    }

    func moveIcon(_ icon: Icon, fromRow: Int, toRow: Int) {
        moveAndRenumber(fromRow: fromRow, toRow: toRow, sortOrder: Icon.primarySortOrder)
        model.saveAndWait()
    }

    func selectIcon(_ icon: Icon) {
        selectedCallback(icon)
    }
}
