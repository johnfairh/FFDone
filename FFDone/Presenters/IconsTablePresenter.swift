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

    // Optional callback + `cancel` for 'once' behaviour on pickIcon used as a directorrequest
    // Should factor out somehow (yet another superclass?) if used elsewhere.
    private var selectedCallback: PresenterDone<Icon>?
    public func cancel() {
        doSelectIcon(nil)
    }

    required init(director: DirectorInterface, model: Model, object: ModelResultsSet?, mode: PresenterMode, dismiss: @escaping PresenterDone<Icon>) {
        self.selectedCallback = dismiss
        super.init(director: director, model: model, object: object, mode: mode)
    }

    func createNewObject() {
        Task {
            if let newIcon = await director.request(.createIcon(model)),
               !shouldEnableExtraControls {
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
        doSelectIcon(icon)
    }

    private func doSelectIcon(_ icon: Icon?) {
        selectedCallback?(icon)
        if !shouldEnableExtraControls {
            selectedCallback = nil
        }
    }

    func updateSearchResults(text: String) {
        handleSearchUpdate(text: text) {
            Icon.searchByNameSortedResultsSet(model: self.model, str: text)
        }
    }
}
