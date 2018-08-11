//
//  IconsTableViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

class IconCell: UITableViewCell, TableCell {
    func configure(_ modelObject: Icon) {
        textLabel?.text  = modelObject.name
//        imageView?.image = modelObject.getStandardImage()
        imageView?.image = modelObject.nativeImage.imageWithSize(CGSize(width: 38, height: 38))
    }
}

class IconsTableViewController: PresentableTableVC<IconsTablePresenter>,
    TableModelDelegate
{
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.reload = { [weak self] queryResults in
            self?.reloadTable(queryResults: queryResults)
        }
        navigationItem.leftBarButtonItem = nil
    }

    private var tableModel: TableModel<IconCell, IconsTableViewController>!

    private func reloadTable(queryResults: ModelResults) {
        tableModel = TableModel(tableView: tableView,
                                fetchedResultsController: queryResults,
                                delegate: self)
        tableModel.start()
    }

    func canDeleteObject(_ modelObject: Icon) -> Bool {
        return presenter.canDeleteIcon(modelObject)
    }

    func deleteObject(_ modelObject: Icon) {
        presenter.deleteIcon(modelObject)
    }

    func canMoveObject(_ modelObject: Icon) -> Bool {
        return presenter.canMoveIcon(modelObject)
    }

    func moveObject(_ from: Icon, fromRow: Int, toRow: Int) {
        presenter.moveIcon(from, fromRow: fromRow, toRow: toRow)
    }

    func selectObject(_ modelObject: ModelObject) {
        presenter.selectIcon(modelObject as! Icon)
    }
}
