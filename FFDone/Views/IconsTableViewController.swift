//
//  IconsTableViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

class IconCell: UITableViewCell, TableCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView?.enableRoundCorners()
        // XXX start temp color stuff
        textLabel?.textColor = .text
        // XXX end temp color stuff
    }

    func configure(_ modelObject: Icon) {
        textLabel?.text  = modelObject.name
        imageView?.image = modelObject.nativeImage.imageWithSize(CGSize(width: 38, height: 38))
    }
}

class IconsTableViewController: PresentableTableVC<IconsTablePresenter>,
    TableModelDelegate
{
    override func viewDidLoad() {
        super.viewDidLoad()

        // XXX start temp color stuff
        view.backgroundColor = .background
        UITableViewCell.appearance(whenContainedInInstancesOf: [IconsTableViewController.self]).backgroundColor = .background
        // XXX end temp color stuff

        presenter.reload = { [weak self] queryResults in
            self?.reloadTable(queryResults: queryResults)
        }
        if presenter.shouldEnableExtraControls {
            navigationItem.leftBarButtonItem = nil
        }
        enableSearch(scopes: [])
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

    public override func updateTableForSearch(text: String, scopeIndex: Int) {
        presenter.updateSearchResults(text: text)
    }
}
