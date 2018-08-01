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
        detailTextLabel?.text = modelObject.progressText
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

    func canDeleteObject(_ modelObject: Goal) -> Bool {
        return presenter.canDeleteGoal(modelObject)
    }

    func deleteObject(_ modelObject: Goal) {
        presenter.deleteGoal(modelObject)
    }

    func canMoveObject(_ modelObject: Goal) -> Bool {
        return presenter.canMoveGoal(modelObject)
    }

    func moveObject(_ from: Goal, fromRow: Int, toRow: Int) {
        presenter.moveGoal(from, fromRow: fromRow, toRow: toRow)
    }

    func selectObject(_ modelObject: ModelObject) {
        presenter.selectGoal(modelObject as! Goal)
    }

    // MARK: - Search

    public func updateSearchResults(for searchController: UISearchController) {
        let text = searchController.searchBar.text ?? ""
        presenter.updateSearchResults(text: text)
    }
}
