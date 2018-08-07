//
//  GoalsTablePresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Interface from the Goal Table VC to presenter -- requirements unique to goal table.
protocol GoalsTablePresenterInterface: TablePresenterInterface {
    var isSearchable: Bool { get }

    func canDeleteGoal(_ goal: Goal) -> Bool
    func deleteGoal(_ goal: Goal)

    func canMoveGoal(_ goal: Goal) -> Bool
    func canMoveGoalTo(_ goal: Goal, toSection: Goal.Section, toRowInSection: Int) -> Bool
    func moveGoal(_ goal: Goal, fromRowInSection: Int, toSection: Goal.Section, toRowInSection: Int, tableView: UITableView)
    func selectGoal(_ goal: Goal)

    func swipeActionForGoal(_ goal: Goal) -> TableSwipeAction?

    func updateSearchResults(text: String, type: GoalsTableSearchType)
}

enum GoalsTableSearchType {
    case name
    case tag
    case either
}

// MARK: - Presenter

class GoalsTablePresenter: TablePresenter<DirectorInterface>, Presenter, GoalsTablePresenterInterface {
    typealias ViewInterfaceType = GoalsTablePresenter//Interface --- XXX weird swift generics vs. protocols runtime crash workaround XXX

    private let selectedCallback: PresenterDone<Goal>

    required init(director: DirectorInterface, model: Model, object: ModelResultsSet?, mode: PresenterMode, dismiss: @escaping PresenterDone<Goal>) {
        self.selectedCallback = dismiss
        super.init(director: director, model: model, object: object, mode: mode)
    }

    var isSearchable: Bool {
        return shouldEnableExtraControls
    }

    func canDeleteGoal(_ goal: Goal) -> Bool {
        return isEditable
    }

    func deleteGoal(_ goal: Goal) {
        goal.delete(from: model)
        model.save()
    }

    func canMoveGoal(_ goal: Goal) -> Bool {
        return isEditable
    }

    /// Check whether move is permitted
    func canMoveGoalTo(_ goal: Goal, toSection: Goal.Section, toRowInSection: Int) -> Bool {
        if goal.isComplete {
            // Can't move complete -> complete, order fixed
            return toSection != .complete
        } else if toSection != .complete {
            return true
        } else {
            // fav/active -> complete, only allow top slot
            return toRowInSection == 0
        }
    }

    /// Process the move.
    func moveGoal(_ goal: Goal, fromRowInSection: Int, toSection: Goal.Section, toRowInSection: Int, tableView: UITableView) {
        Log.assert(canMoveGoalTo(goal, toSection: toSection, toRowInSection: toRowInSection))

        let fromSection = goal.section

        moveAndRenumber(fromSectionName: fromSection.rawValue, fromRowInSection: fromRowInSection,
                        toSectionName: toSection.rawValue, toRowInSection: toRowInSection,
                        sortOrder: Goal.primarySortOrder)

        // If we are changing section then there is additional stuff to do to preserve
        // the sort-order invariants.
        if fromSection != toSection {
            goal.userMove(newSection: toSection)

            // Using row-move to empty a section is problematic.
            //
            // It worked perfectly in the "edit mode -> drag the ear" world by throwing this
            // next `deleteSections` onto a fibre.
            //
            // But this crashes in the "drag and drop" world in iOS11 and iOS12 (Xcode 10b5)
            // in different ways depending on when it's called -- see TableModel.swift.
            //
            // So we prevent this ever from happening instead, again see TableModel.swift.
            //
            let fromSectionRowCount = getSectionRowCount(sectionName: fromSection.rawValue)
            let fromSectionIndex    = getSectionIndex(sectionName: fromSection.rawValue)

            if fromSectionRowCount == 1 { // ie. before the move
                Log.fatal("Help, shouldn't be allowed to empty a section using move")
                #if false
                // We emptied the section - have to delete it and adjust...
                Log.log("Deleted section '\(fromSection.rawValue)' current index \(fromSectionIndex)")
                tableView.deleteSections(IndexSet(integer: fromSectionIndex), with: .none)
                #endif
            }
        }
        model.saveAndWait()
    }

    func selectGoal(_ goal: Goal) {
        selectedCallback(goal)
    }

    func createNewObject() {
        director.request(.createGoal(model))
    }

    // MARK: - Swipe

    func swipeActionForGoal(_ goal: Goal) -> TableSwipeAction? {
        guard !goal.isComplete else {
            return nil
        }

        let title = (goal.stepsToGo == 1) ? "Complete" : "Progress"

        return TableSwipeAction(text: title, colorName: "StepSwipeColour", action: {
            goal.currentSteps = goal.currentSteps + 1
            self.model.save()
        })
    }

    enum SearchDelayState {
        case idle
        case delaying
        case delaying_again
    }

    var searchDelayState: SearchDelayState = .idle
    var searchText: String = ""
    var searchType: GoalsTableSearchType = .either

    func updateSearchResults(text: String, type: GoalsTableSearchType) {
        if text.isEmpty {
            searchDelayState = .idle
            if filteredResults != nil {
                filteredResults = nil
            }
        } else {
            searchText = text
            searchType = type
            switch searchDelayState {
            case .idle:
                delaySearch()
            case .delaying:
                searchDelayState = .delaying_again
            case .delaying_again:
                break
            }
        }
    }

    func delaySearch() {
        searchDelayState = .delaying
        Dispatch.toForegroundAfter(milliseconds: 150, block: updateSearchResultsDelayed)
    }

    func updateSearchResultsDelayed() {
        switch searchDelayState {
        case .idle:
            break
        case .delaying_again:
            delaySearch()
        case .delaying:
            searchDelayState = .idle
            switch searchType {
            case .either:
                filteredResults = Goal.searchByAnythingSortedResultsSet(model: model, text: searchText)
            case .name:
                filteredResults = Goal.searchByNameSortedResultsSet(model: model, name: searchText)
            case .tag:
                filteredResults = Goal.searchByTagSortedResultsSet(model: model, tag: searchText)
            }
        }
    }
}
