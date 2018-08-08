//
//  GoalEditViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Hard-code a bit of knowledge about the dialog static table layout
private extension IndexPath {
    var isCurrentStepsRow: Bool {
        return section == 0 && row == 2
    }

    var isIconRow: Bool {
        return section == 0 && row == 1
    }

    var isNotesTableRow: Bool {
        return section == 1 && row == 1
    }
}

/// VC for goal create/edit
class GoalEditViewController: PresentableBasicTableVC<GoalEditPresenterInterface>,
                              UITextFieldDelegate {

    // MARK: Controls
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var currentStepsTextField: UITextField!
    @IBOutlet weak var currentStepsStepper: UIStepper!
    @IBOutlet weak var totalStepsTextField: UITextField!
    @IBOutlet weak var totalStepsStepper: UIStepper!
    @IBOutlet weak var favToggle: UISwitch!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var tagTextField: UITextField!

    @IBAction func addNoteButtonTapped(_ sender: UIButton) {
        presenter.addNote()
        Dispatch.toForeground {
            self.refreshRowHeights()
        }
    }
    
    private weak var notesTableVC: GoalNotesTableViewController!
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        nameTextField.delegate = self
        currentStepsTextField.delegate = self
        totalStepsTextField.delegate = self
        tagTextField.delegate = self

        presenter.refresh = { [unowned self] goal, isSaveOK in
            self.nameTextField.text = goal.name
            self.iconImage.image = goal.nativeImage
            self.currentStepsTextField.text = String(goal.currentSteps)
            self.currentStepsStepper.value = Double(goal.currentSteps)
            self.totalStepsTextField.text = String(goal.totalSteps)
            self.totalStepsStepper.value = Double(goal.totalSteps)
            self.favToggle.isOn = goal.isFav
            self.tagTextField.text = goal.tag
            self.doneButton.isEnabled = isSaveOK
        }
    }

    // MARK: Simple control reactions

    @IBAction func currentStepperDidChange(_ sender: UIStepper) {
        presenter.setCurrentSteps(steps: Int(sender.value))
    }

    @IBAction func totalStepperDidChange(_ sender: UIStepper) {
        presenter.setTotalSteps(steps: Int(sender.value))
    }

    @IBAction func favDidChange(_ sender: UISwitch) {
        presenter.setFav(fav: sender.isOn)
    }
    
    @IBAction func cancelButtonDidTap(_ sender: UIBarButtonItem) {
        presenter.cancel()
    }

    @IBAction func doneButtonDidTap(_ sender: UIBarButtonItem) {
        presenter.save()
    }

    // MARK: Text stuff

    // Close the keyboard when appropriate, plus listen live for changes
    // to the fields and update everything, sanitizing the step entries.
    //
    // Autocomplete the tag field against existing tags.

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField === tagTextField else {
            return true
        }
        return !textField.autoCompleteText(newText: string, suggestions: App.shared.tags)
    }

    private var nameListener: NotificationListener!
    private var currentStepsListener: NotificationListener!
    private var totalStepsListener: NotificationListener!
    private var tagListener: NotificationListener!

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        nameListener = NotificationListener(
            name: UITextField.textDidChangeNotification,
            from: nameTextField) { [unowned self] _ in
                self.presenter.setGoalName(name: self.nameTextField.text!)
        }

        currentStepsListener = NotificationListener(
            name: UITextField.textDidChangeNotification,
            from: currentStepsTextField) { [unowned self] _ in
                if let newValue = Int(self.currentStepsTextField.text!) {
                    self.presenter.setCurrentSteps(steps: newValue)
                }
        }

        totalStepsListener = NotificationListener(
            name: UITextField.textDidChangeNotification,
            from: totalStepsTextField) { [unowned self] _ in
                /// Here we allow a transient zero to happen during editting
                if let newValue = Int(self.totalStepsTextField.text!), newValue > 0 {
                    self.presenter.setTotalSteps(steps: newValue)
                }
        }

        tagListener = NotificationListener(
            name: UITextField.textDidChangeNotification,
            from: tagTextField) { [unowned self] _ in
                let text = self.tagTextField.text
                if text == nil || text!.isEmpty {
                    self.presenter.setTag(tag: nil)
                } else {
                    self.presenter.setTag(tag: text!)
                }
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        nameListener.stopListening()
        currentStepsListener.stopListening()
        totalStepsListener.stopListening()
        tagListener.stopListening()
    }

    // MARK: Table stuff

    // Dealing with the embedded notes table is a bit tricksy, can't figure out how to autolink
    // the content size of the embedded tableview to the preferred height of the cell.
    //
    // So we notice when things change and manually refresh the layout.
    func refreshRowHeights() {
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    // Hide the 'current steps' control in the create-new use case
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if !presenter.canEditCurrentSteps && indexPath.isCurrentStepsRow {
            return 0
        }
        if indexPath.isNotesTableRow {
            return notesTableVC.tableView.contentSize.height
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }

    // Allow the 'icon' row to highlight
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.isIconRow
    }

    // Trigger the icon picker
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.isIconRow {
            presenter.pickIcon()
        }
    }

    /// This gets called (for the embed segue) before viewDidLoad()
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let notesTableVC = segue.destination as? GoalNotesTableViewController {
            self.notesTableVC = notesTableVC
            notesTableVC.contentDidChange = { [weak self] in self?.refreshRowHeights() }
            PresenterUI.bind(viewController: notesTableVC, presenter: presenter.createNotesPresenter())
        }
    }
}


class GoalNoteCell: UITableViewCell, TableCell {

    @IBOutlet weak var noteLabel: UILabel!
    
    func configure(_ note: Note) {
        noteLabel.text = note.text
    }
}

class GoalNotesTableViewController: PresentableTableVC<GoalNotesTablePresenter>,
    TableModelDelegate
{

    var contentDidChange: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.reload = { [weak self] queryResults in
            self?.reloadTable(queryResults: queryResults)
        }
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

    func canDeleteObject(_ note: Note) -> Bool {
        return true
    }

    func deleteObject(_ note: Note) {
        presenter.deleteNote(note)
        Dispatch.toForegroundAfter(milliseconds: 200) {
            self.contentDidChange?()
        }
    }
}
