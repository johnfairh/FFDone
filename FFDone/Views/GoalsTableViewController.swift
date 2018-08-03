//
//  GoalsTableViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

class GoalCell: UITableViewCell, TableCell {
    func configure(_ modelObject: Goal) {
        textLabel?.text       = modelObject.name
        detailTextLabel?.text = modelObject.progressText + modelObject.debugText
        imageView?.image      = modelObject.badgedImage
    }
}

class GoalsTableViewController: PresentableTableVC<GoalsTablePresenter>,
    TableModelDelegate,
    UISearchResultsUpdating
{
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.reload = { [weak self] queryResults in
            self?.reloadTable(queryResults: queryResults)
        }

        if presenter.isSearchable {
            let searchController = UISearchController(searchResultsController: nil)
            searchController.obscuresBackgroundDuringPresentation = false
            searchController.searchBar.autocapitalizationType = .none
            searchController.searchResultsUpdater = self
            navigationItem.searchController = searchController
            definesPresentationContext = true
        }
    }

    private var tableModel: TableModel<GoalCell, GoalsTableViewController>!

    private func reloadTable(queryResults: ModelResults) {
        tableModel = TableModel(tableView: tableView,
                                fetchedResultsController: queryResults,
                                delegate: self)
        tableModel.start()
    }

    // MARK: - Section config
    func getSectionTitle(name: String) -> String {
        return GoalSection.titleMap[name]!
    }

    func getSectionObject(name: String) -> GoalSection {
        return GoalSection(rawValue: name)!
    }

    // MARK: - Delete

    func canDeleteObject(_ modelObject: Goal) -> Bool {
        return presenter.canDeleteGoal(modelObject)
    }

    func deleteObject(_ modelObject: Goal) {
        presenter.deleteGoal(modelObject)
    }

    // MARK: - Move

    func canMoveObject(_ modelObject: Goal) -> Bool {
        return presenter.canMoveGoal(modelObject)
    }

    func canMoveObjectTo(_ modelObject: Goal, toSection: GoalSection, toRowInSection: Int) -> Bool {
        return true
    }

    func moveObject(_ goal: Goal,
                    fromSection: GoalSection, fromRowInSection: Int,
                    toSection: GoalSection, toRowInSection: Int) {
        presenter.moveGoal(goal,
                           fromSection: fromSection, fromRowInSection: fromRowInSection,
                           toSection: toSection, toRowInSection: toRowInSection)
    }

    // MARK: - Select

    func selectObject(_ modelObject: ModelObject) {
        presenter.selectGoal(modelObject as! Goal)
    }

    func leadingSwipeActionsForObject(_ goal: Goal) -> UISwipeActionsConfiguration? {
        guard !goal.isComplete else {
            return nil
        }
        // TODO: these things should move to `Goal`
        let title = (goal.stepsToGo == 1) ? "Complete" : "Progress"
        let action = UIContextualAction(style: .normal, title: title) { _, _, continuation in
            goal.currentSteps = goal.currentSteps + 1
            continuation(true)
        }
        action.backgroundColor = UIColor(named: "StepSwipeColour") ?? .green
        return UISwipeActionsConfiguration(actions: [action])
    }

    // MARK: - Search

    public func updateSearchResults(for searchController: UISearchController) {
        let text = searchController.searchBar.text ?? ""
        presenter.updateSearchResults(text: text)
    }
}
