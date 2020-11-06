//
//  EpochsTableViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

class EpochCell: UITableViewCell, TableCell {
    @IBOutlet weak var epochImage: UIImageView!
    @IBOutlet weak var epochPatchLabel: UILabel!
    @IBOutlet weak var epochPeriodLabel: UILabel!

    func configure(_ modelObject: Epoch) {
        epochPatchLabel.text = modelObject.versionText
        epochPeriodLabel.text = modelObject.dateIntervalText
        // If I let this scale automatically then the cell ends up with
        // vertical padding around the image.
        let newWidth = epochImage.frame.width
        let imageSize = modelObject.image.size
        let newHeight = (newWidth * imageSize.height) / imageSize.width
        epochImage.image = modelObject.image.imageWithSize(CGSize(width: newWidth, height: newHeight))
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
