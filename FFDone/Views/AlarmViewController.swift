//
//  AlarmViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

class AlarmViewController: PresentableVC<AlarmViewPresenterInterface> {

    // MARK: Controls
    @IBOutlet weak var alarmImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var doneSwitch: UISwitch!
    @IBOutlet weak var notesTextView: UITextView!

    public override func viewDidLoad() {
        super.viewDidLoad()

        presenter.refresh = { [unowned self] alarm in
            self.alarmImage.image = alarm.mainTableImage
            self.titleLabel.text = alarm.name
            self.subtitleLabel.text = alarm.caption
            self.doneSwitch.isOn = alarm.isActive
            self.doneSwitch.isEnabled = alarm.isActive
            self.notesTextView.text = alarm.notes
        }
    }
    
    @IBAction func doneSwitchTapped(_ sender: UISwitch) {
        presenter.complete()
    }

    @IBAction func editNotesButtonTapped(_ sender: UIButton) {
        presenter.editNotes()
    }

    @IBAction func editAlarmTapped(_ sender: UIBarButtonItem) {
        presenter.edit()
    }
}
