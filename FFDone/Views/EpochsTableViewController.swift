//
//  EpochsTableViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

class EpochCell: UITableViewCell, TableCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView?.enableRoundCorners()
    }

    func configure(_ modelObject: Epoch) {
        textLabel?.text  = modelObject.longName
        imageView?.image = modelObject.image
    }
}

class EpochsTableViewController: PresentableTableVC<EpochsTablePresenter>,
                                 TableModelDelegate {
    typealias ModelType = Epoch

    override func viewDidLoad() {
        super.viewDidLoad()

        presenter.reload = { [weak self] queryResults in
            self?.reloadTable(queryResults: queryResults)
        }
        enablePullToCreate()
        navigationItem.leftBarButtonItem = nil
    }

    private var tableModel: TableModel<EpochCell, EpochsTableViewController>!

    private func reloadTable(queryResults: ModelResults) {
        tableModel = TableModel(tableView: tableView,
                                fetchedResultsController: queryResults,
                                delegate: self)
        tableModel.start()
    }

    @IBAction func debugButtonTapped(_ sender: UIBarButtonItem) {
        presenter.showDebug()
    }
}
