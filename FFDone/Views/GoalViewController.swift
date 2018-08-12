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

    @IBOutlet weak var multistepLabel: UILabel!
    @IBOutlet weak var multistepStepper: UIStepper!
    @IBOutlet weak var multistepStackView: UIStackView!

    @IBOutlet weak var singleStepSwitch: UISwitch!


    public override func viewDidLoad() {
        super.viewDidLoad()

        presenter.refresh = { [unowned self] goal in
            self.imageView.image = goal.badgedImage
            self.titleLabel.text = goal.name
            self.progressLabel.text = "Progress"

            self.multistepLabel.text = "1 of 2"
            self.multistepStepper.value = Double(goal.currentSteps)
            self.singleStepSwitch.isHidden = true
        }
    }

    @IBAction func didTapEditButton(_ sender: UIBarButtonItem) {
        presenter.edit()
    }
    
    @IBAction func didTapAddNoteButton(_ sender: UIButton) {
    }
}
