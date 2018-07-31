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

    public override func viewDidLoad() {
        super.viewDidLoad()

        nameTextField.delegate = self
        currentStepsTextField.delegate = self
        totalStepsTextField.delegate = self

        presenter.refresh = { [unowned self] goal in
            self.nameTextField.text = goal.name
            self.iconImage.image = goal.nativeImage
            self.currentStepsTextField.text = String(goal.currentSteps)
            self.currentStepsStepper.value = Double(goal.currentSteps)
            self.totalStepsTextField.text = String(goal.totalSteps)
            self.totalStepsStepper.value = Double(goal.totalSteps)
            self.favToggle.isOn = goal.isFav
            self.doneButton.isEnabled = self.presenter.isSaveAllowed
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

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    private var nameListener: NotificationListener!
    private var currentStepsListener: NotificationListener!
    private var totalStepsListener: NotificationListener!

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
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        nameListener.stopListening()
        currentStepsListener.stopListening()
        totalStepsListener.stopListening()
    }

    // MARK: Table stuff

    // Hide the 'current steps' control in the create-new use case
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if !presenter.canEditCurrentSteps && indexPath.isCurrentStepsRow {
            return 0
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
}
