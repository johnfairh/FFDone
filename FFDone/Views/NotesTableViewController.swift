//
//  NotesTableViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

class NoteCell: UITableViewCell, TableCell {
    func configure(_ modelObject: Note) {
        textLabel?.text  = modelObject.text
    }
}

class NotesTableViewController: PresentableTableVC<NotesTablePresenter>,
    TableModelDelegate
{
    typealias ModelType = Note

    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.reload = { [weak self] queryResults in
            self?.reloadTable(queryResults: queryResults)
        }
    }

    private var tableModel: TableModel<NoteCell, NotesTableViewController>!

    private func reloadTable(queryResults: ModelResults) {
        tableModel = TableModel(tableView: tableView,
                                fetchedResultsController: queryResults,
                                delegate: self)
        tableModel.start()
    }

    func selectObject(_ modelObject: ModelObject) {
        presenter.selectNote(modelObject as! Note)
    }
}
