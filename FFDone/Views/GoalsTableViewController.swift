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
        detailTextLabel?.text = "details here"

        imageView?.image = modelObject.icon?.getStandardImage()
//
//        switch modelObject.sortOrder {
//        case 0: imageView?.image = UIImage(named: "DefGoal_Bard")!.imageWithSize(CGSize(width: 43, height: 43))
//        case 1: imageView?.image = UIImage(named: "DefGoal_Crafting")!.imageWithSize(CGSize(width: 43, height: 43))
//        default: imageView?.image = UIImage(named: "DefGoal_UnlockQuest")!.imageWithSize(CGSize(width: 43, height: 43))
//        }
    }
}

class GoalsTableViewController: PresentableTableVC<GoalsTablePresenter>,
    TableModelDelegate
{
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.reload = { [weak self] queryResults in
            self?.reloadTable(queryResults: queryResults)
        }
    }

    private var tableModel: TableModel<GoalCell, GoalsTableViewController>!

    private func reloadTable(queryResults: ModelResults) {
        tableModel = TableModel(tableView: tableView,
                                fetchedResultsController: queryResults,
                                delegate: self)
        tableModel.start()
    }

    func createNewObject() {
        presenter.createNewObject()
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
}
