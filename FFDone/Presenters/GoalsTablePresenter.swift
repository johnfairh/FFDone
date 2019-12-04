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

    var tags: [String] { get }
    func updateSearchResults(date: Date?, text: String, type: GoalsTableSearchType)

    var invokeSearch: (GoalsTableInvocationData) -> Void { get set }
}

/// What is being searched for
enum GoalsTableSearchType: Int {
    case both = 0
    case name = 1
    case tag = 2
}

/// Packet passed from elsewhere to set the default search
struct GoalsTableInvocationData {
    let date: Date
    let tag: String
    let epochName: String

    init(from date: Date, tagged tag: String, epochName: String) {
        self.date = date
        self.tag = tag
        self.epochName = epochName
    }
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

        return TableSwipeAction(text: title, color: .tableLeadingSwipe, action: {
            goal.currentSteps = goal.currentSteps + 1
            self.model.save()
        })
    }

    // MARK: - Search

    var tags: [String] {
        return director.tags
    }

    func updateSearchResults(date: Date?, text: String, type: GoalsTableSearchType) {
        handleSearchUpdate(text: text) {
            switch type {
            case .both:
                return Goal.searchByAnythingSortedResultsSet(model: self.model, date: date, text: text)
            case .name:
                return Goal.searchByNameSortedResultsSet(model: self.model, date: date, name: text)
            case .tag:
                return Goal.searchByTagSortedResultsSet(model: self.model, date: date, tag: text)
            }
        }
    }

    // MARK: - Invocation

    // Painfully this can happen before the view has loaded and so we need
    // to deal with that ordering of events as well as the more convenient
    // one.

    enum InvocationState {
        case idle
        case waiting(GoalsTableInvocationData)
        case ready((GoalsTableInvocationData) -> Void)

        mutating func send(data: GoalsTableInvocationData) {
            switch self {
            case .idle, .waiting(_):
                self = .waiting(data)
            case .ready(let uiFn):
                uiFn(data)
            }
        }

        mutating func register(uiFunc: @escaping (GoalsTableInvocationData) -> Void) {
            let previous = self
            self = .ready(uiFunc)
            if case .waiting(let data) = previous {
                send(data: data)
            }
        }
    }

    var invocationState: InvocationState = .idle

    var invokeSearch: (GoalsTableInvocationData) -> Void {
        set {
            invocationState.register(uiFunc: newValue)
        }
        get {
            return { _ in }
        }
    }

    func invoke(with data: GoalsTableInvocationData) {
        invocationState.send(data: data)
    }
}

