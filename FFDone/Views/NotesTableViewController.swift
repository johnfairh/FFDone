//
//  NotesTableViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation
import DatePickerDialog

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
    private var datePicker: DatePickerDialog!

    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.reload = { [weak self] queryResults in
            self?.reloadTable(queryResults: queryResults)
        }
        if presenter.shouldEnableExtraControls {
            navigationItem.leftBarButtonItem = nil
            enableSearch(scopes: [])
        }
        datePicker = DatePickerDialog(textColor: .darkText,
                                      buttonColor: UIButton(type: .system).currentTitleColor,
                                      font: .systemFont(ofSize: 15.0),
                                      showCancelButton: false)
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

    // MARK: - Object actions

    func canDeleteObject(_ modelObject: Note) -> Bool {
        return true
    }

    func deleteObject(_ note: Note) {
        presenter.deleteNote(note)
    }

    func selectObject(_ modelObject: ModelObject) {
        presenter.selectNote(modelObject as! Note)
    }

    // MARK: - UI fanciness

    public override func updateTableForSearch(text: String, scopeIndex: Int) {
        presenter.updateSearchResults(text: text)
    }

    @IBAction func didTapCalendarButton(_ sender: UIBarButtonItem) {
        datePicker.show("Skip to date",
                        doneButtonTitle: "OK",
                        cancelButtonTitle: "Cancel",
                        defaultDate: Date(),
                        datePickerMode: .date) { newDate in
                            if let newDate = newDate {
                                print("New date: \(newDate)")
                            }
        }
    }

    @IBAction func didTapReverseButton(_ sender: UIBarButtonItem) {
        presenter.reverseNoteOrder()
    }
}
