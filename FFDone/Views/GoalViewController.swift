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

    public override func viewDidLoad() {
        super.viewDidLoad()
        imageView.enableRoundCorners()
        multistepTextField.delegate = self

        presenter.refresh = { [unowned self] goal in
            self.imageView.image = goal.getBadgedImage(size: self.imageView.frame.size)
            self.titleLabel.text = goal.name
            self.progressLabel.text = goal.longProgressText

            // All attempts at animating transitions here failed horribly.
            if goal.isComplete {
                self.multistepStackView.isHidden = true
                self.singleStepSwitch.isHidden = true
            } else if goal.hasSteps {
                self.multistepTextField.text = goal.stepsStatusText
                self.multistepStepper.value = Double(goal.currentSteps)
                self.singleStepSwitch.isHidden = true
            } else {
                self.singleStepSwitch.isOn = false // because goal !complete
                self.multistepStackView.isHidden = true
            }
        }
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
        if let text = textField.text,
            let stepsValue = Int(text) {
            presenter.setCurrentSteps(steps: stepsValue)
        } else {
            textField.text = savedTextField
        }
        textField.resignFirstResponder()
        return true
    }
}
