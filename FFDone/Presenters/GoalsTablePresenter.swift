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
    func canMoveGoalTo(_ goal: Goal, toSection: GoalSection, toRowInSection: Int) -> Bool
    func moveGoal(_ goal: Goal, fromSection: GoalSection, fromRowInSection: Int, toSection: GoalSection, toRowInSection: Int)
    func selectGoal(_ goal: Goal)

    func updateSearchResults(text: String)
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

    func canMoveGoalTo(_ goal: Goal, toSection: GoalSection, toRowInSection: Int) -> Bool {
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

    func moveGoal(_ goal: Goal, fromSection: GoalSection, fromRowInSection: Int, toSection: GoalSection, toRowInSection: Int) {
        moveAndRenumber(fromSectionName: fromSection.rawValue, fromRowInSection: fromRowInSection,
                        toSectionName: toSection.rawValue, toRowInSection: toRowInSection,
                        sortOrder: Goal.primarySortOrder)
        model.saveAndWait()
    }

    func selectGoal(_ goal: Goal) {
        selectedCallback(goal)
    }

    func createNewObject() {
        director.request(.createGoal(model))
    }

    enum SearchDelayState {
        case idle
        case delaying
        case delaying_again
    }

    var searchDelayState: SearchDelayState = .idle
    var searchText: String = ""

    func updateSearchResults(text: String) {
        if text.isEmpty {
            searchDelayState = .idle
            if filteredResults != nil {
                filteredResults = nil
            }
        } else {
            searchText = text
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
            filteredResults = Goal.matchingSortedResultsSet(model: model, string: searchText)
        }
    }
}
