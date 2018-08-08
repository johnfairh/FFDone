//
//  NotesTableViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

class NoteCell: UITableViewCell, TableCell {

    @IBOutlet weak var goalStackView: UIStackView!
    @IBOutlet weak var goalImageView: UIImageView!
    @IBOutlet weak var goalNameButton: UIButton!
    @IBOutlet weak var noteLabel: UILabel!

    func configure(_ note: Note) {
        goalImageView.image = note.goal?.nativeImage
        goalNameButton.setTitle(note.goal?.name ?? "??", for: .normal)
        noteLabel.text = note.text
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
        navigationItem.leftBarButtonItem = nil
    }

    private var tableModel: TableModel<NoteCell, NotesTableViewController>!

    private func reloadTable(queryResults: ModelResults) {
        tableModel = TableModel(tableView: tableView,
                                fetchedResultsController: queryResults,
                                delegate: self)
        tableModel.start()
    }

    func getSectionTitle(name: String) -> String {
        return Note.dayStampToUserString(dayStamp: name)
    }

    func selectObject(_ modelObject: ModelObject) {
        presenter.selectNote(modelObject as! Note)
    }
}
