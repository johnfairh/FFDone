//
//  GoalNotesTableViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// This is a VC for the notes table that embeds inside the
/// goal-view and goal-edit main VCs.
class GoalNoteCell: UITableViewCell, TableCell {

    @IBOutlet weak var noteLabel: UILabel!

    func configure(_ note: Note) {
        noteLabel.text = note.text
        // XXX start temp coloring
        noteLabel.textColor = .text
        backgroundColor = nil
        // XXX end temp coloring
    }
}

class GoalNotesTableViewController: PresentableTableVC<GoalNotesTablePresenter>, TableModelDelegate {

    /// How big the table would like to be -- could be bigger than the screen.
    var desiredHeight: CGFloat {
        return tableView.contentSize.height
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setBasicColors()

        presenter.reload = { [weak self] queryResults in
            self?.reloadTable(queryResults: queryResults)
        }
    }

    func willDisplaySectionHeader(_ header: UITableViewHeaderFooterView) {
        // XXX start temp coloring
        header.textLabel?.textColor = .text
        header.tintColor = .tableHeader // bizarrely this sets the background color
        // XXX end temp coloring
    }

    private var tableModel: TableModel<GoalNoteCell, GoalNotesTableViewController>!

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

    func canDeleteObject(_ note: Note) -> Bool {
        return true
    }

    func deleteObject(_ note: Note) {
        presenter.deleteNote(note)
    }
}
