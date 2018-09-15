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
    @IBOutlet weak var currentStepsLabel: UILabel!
    @IBOutlet weak var totalStepsLabel: UILabel!
    
    private weak var notesTableVC: GoalNotesTableViewController!

    public override func viewDidLoad() {
        super.viewDidLoad()
        setFormTableColors()

        nameTextField.delegate = self
        currentStepsTextField.delegate = self
        totalStepsTextField.delegate = self
        tagTextField.delegate = self

        currentStepsLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapCurrentSteps)))
        totalStepsLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapTotalSteps)))

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
            self.refreshRowHeights()
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

    @IBAction func addNoteButtonTapped(_ sender: UIButton) {
        presenter.addNote()
    }

    @objc
    func didTapCurrentSteps() {
        currentStepsTextField.becomeFirstResponder()
    }

    @objc
    func didTapTotalSteps() {
        totalStepsTextField.becomeFirstResponder()
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
        guard textField.autoCompleteText(newText: string, suggestions: presenter.tags) else {
            return true
        }
        presenter.setTag(tag: textField.text!)
        return false
    }

    @IBAction func nameTextFieldDidChange(_ sender: UITextField, forEvent event: UIEvent) {
        presenter.setGoalName(name: sender.text!)
    }

    @IBAction func currentStepsTextFieldDidChange(_ sender: UITextField) {
        if let newValue = Int(sender.text!) {
            presenter.setCurrentSteps(steps: newValue)
        }
    }

    @IBAction func totalStepsTextFieldDidChange(_ sender: UITextField) {
        /// Here we allow a transient zero to happen during editting
        if let newValue = Int(sender.text!), newValue > 0 {
            presenter.setTotalSteps(steps: newValue)
        }
    }
    
    @IBAction func tagTextFieldDidChange(_ sender: UITextField) {
        if let text = sender.text, !text.isEmpty {
            presenter.setTag(tag: text)
        } else {
            presenter.setTag(tag: nil)
        }
    }

    // MARK: Table stuff

    // Dealing with the embedded notes table is a bit tricksy, can't figure out how to autolink
    // the content size of the embedded tableview to the preferred height of the cell.
    //
    // So we notice when things change and manually refresh the layout.  Not at all proud of
    // this, but empirically it's what's needed, something to do with the section headers in
    // the embedded table means that it takes two rounds for everything to come out with the
    // right values.  And of course I have no idea what is up with the timed delay.  Argh.
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshRowHeights()
    }

    func refreshRowHeights() {
        Dispatch.toForegroundAfter(milliseconds: 100) {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
            Dispatch.toForeground {
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }
        }
    }

    // Hide the 'current steps' control in the create-new use case
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if !presenter.canEditCurrentSteps && indexPath.isCurrentStepsRow {
            return 0
        }
        if indexPath.isNotesTableRow {
            return notesTableVC.desiredHeight
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
            PresenterUI.bind(viewController: notesTableVC, presenter: presenter.createNotesPresenter())
        }
    }
}
