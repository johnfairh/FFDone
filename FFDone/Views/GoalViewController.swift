//
//  GoalViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

class GoalViewController: PresentableVC<GoalViewPresenterInterface>,
UITextFieldDelegate {

    // MARK: Controls
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!

    @IBOutlet weak var multistepTextField: UITextField!
    @IBOutlet weak var multistepStepper: UIStepper!
    @IBOutlet weak var multistepStackView: UIStackView!

    @IBOutlet weak var singleStepSwitch: UISwitch!

    @IBOutlet weak var notesTableHeightConstraint: NSLayoutConstraint!
    weak var notesTableVC: GoalNotesTableViewController!

    public override func viewDidLoad() {
        super.viewDidLoad()
        imageView.enableRoundCorners()
        multistepTextField.delegate = self
        notesTableVC.tableView.isScrollEnabled = true // enabled=f by default

        presenter.refresh = { [unowned self] goal in
            self.imageView.image = goal.getBadgedImage(size: self.imageView.frame.size)
            self.titleLabel.text = goal.name
            self.progressLabel.text = goal.longProgressText

            // All attempts at animating transitions here failed horribly.
            if goal.isComplete {
                self.multistepStackView.isHidden = true
                self.singleStepSwitch.isHidden = true
            } else if goal.hasSteps {
                self.multistepStackView.isHidden = false
                self.multistepTextField.text = goal.stepsStatusText
                self.multistepStepper.value = Double(goal.currentSteps)
                self.singleStepSwitch.isHidden = true
            } else {
                self.singleStepSwitch.isHidden = false
                self.singleStepSwitch.isOn = true // switch look tempting to press
                self.multistepStackView.isHidden = true
            }
            self.refreshNotesTableHeight()
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshNotesTableHeight()
    }

    // MARK: - Control actions
    
    @IBAction func didChangeMultiStepper(_ sender: UIStepper) {
        presenter.setCurrentSteps(steps: Int(sender.value))
    }

    @IBAction func didChangeSingleStepSwitch(_ sender: UISwitch) {
        presenter.setCurrentSteps(steps: 1)
    }

    @IBAction func didTapEditButton(_ sender: UIBarButtonItem) {
        presenter.edit()
    }
    
    @IBAction func didTapAddNoteButton(_ sender: UIButton) {
        presenter.addNote()
    }

    // MARK: - Textfield

    var savedTextField: String?

    func textFieldDidBeginEditing(_ textField: UITextField) {
        Dispatch.toForeground {
            self.savedTextField = self.multistepTextField.text
            self.multistepTextField.selectAll(nil)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text,
            let stepsValue = Int(text) {
            presenter.setCurrentSteps(steps: stepsValue)
        } else {
            textField.text = savedTextField
        }
    }

    // MARK: - Notes table

    // Again this is a hot mess, tableview seems to need two passes to sort out the
    // height with the section headings.

    var maxTableViewHeight: CGFloat {
        let margin = CGFloat(8)
        let notesTableOrigin: CGPoint = notesTableVC.tableView.convert(.zero, to: view)
        return view.frame.height - notesTableOrigin.y - view.safeAreaInsets.bottom - margin
    }

    private func updateTableHeight() {
        let desiredTableHeight = notesTableVC.desiredHeight
        notesTableHeightConstraint.constant = min(desiredTableHeight, maxTableViewHeight)
        view.layoutIfNeeded()
    }

    func refreshNotesTableHeight() {
        Dispatch.toForegroundAfter(milliseconds: 100) {
            self.updateTableHeight()
            Dispatch.toForeground {
                self.updateTableHeight()
            }
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
