//
//  IconsTablePresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Interface from the Icons Table VC to presenter -- requirements unique to icons table.
@MainActor
protocol IconsTablePresenterInterface: TablePresenterInterface {
    func canDeleteIcon(_ icon: Icon) -> Bool
    func deleteIcon(_ icon: Icon)
    func canMoveIcon(_ icon: Icon) -> Bool
    func moveIcon(_ icon: Icon, fromRow: Int, toRow: Int)
    func selectIcon(_ icon: Icon)
    func updateSearchResults(text: String)
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
        Task {
            let newIcon = await director.request(.createIcon(model))
            // Hack to allow selection from picker on icon creation.
            // Without the hack delay we get ahead of the UI and it all
            // goes wrong.  Attempting to interlock failed via NSFetchResultController,
            // gave up then.
            if !newIcon.none && !shouldEnableExtraControls {
                try? await Task.sleep(nanoseconds: 500 * 1000 * 1000)
                selectIcon(newIcon.icon)
            }
        }
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

    func updateSearchResults(text: String) {
        handleSearchUpdate(text: text) {
            Icon.searchByNameSortedResultsSet(model: self.model, str: text)
        }
    }
}
