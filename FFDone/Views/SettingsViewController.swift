//
//  SettingsViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Hard-code a bit of knowledge about the dialog static table layout
private extension IndexPath {
    var isEpochDateRow: Bool {
        return section == 0 && row == 1
    }

    var isEpochDatePickerRow: Bool {
        return section == 0 && row == 2
    }

    var isDebugRow: Bool {
        return section == 1 && row == 0
    }
}

/// VC for settings window
class SettingsViewController: PresentableBasicTableVC<SettingsPresenterInterface> {
    @IBOutlet weak var enableEpochSwitch: UISwitch!
    @IBOutlet weak var epochStartLabel: UILabel!
    @IBOutlet weak var epochStartDatePicker: UIDatePicker!

    private var edittingDate = false
    private let dateFormatter = DateFormatter()

    public override func viewDidLoad() {
        super.viewDidLoad()

        edittingDate = false
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        presenter.refresh = { [unowned self] enable, date in
            self.enableEpochSwitch.isOn = enable
            if !enable {
                self.edittingDate = false
            }
            self.epochStartLabel.text = self.dateFormatter.string(from: date)
            self.epochStartDatePicker.setDate(date, animated: false)
            self.refreshRowHeights()
        }
    }

    // MARK: - Input forwarders

    @IBAction func epochEnabledToggled(_ sender: UISwitch) {
        presenter.enableEpochs(sender.isOn)
    }

    @IBAction func epochStartDateChanged(_ sender: UIDatePicker) {
        presenter.setEpochDate(sender.date)
    }

    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        presenter.close()
    }

    // MARK: - Table view stuff

    func refreshRowHeights() {
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    // Hide the 'current steps' control in the create-new use case
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if !enableEpochSwitch.isOn && indexPath.isEpochDateRow {
            return 0
        }
        if !edittingDate && indexPath.isEpochDatePickerRow {
            return 0
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }

    // Allow rows to highlight if they do things
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.isDebugRow || indexPath.isEpochDateRow
    }

    // Trigger the icon picker
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.isDebugRow {
            presenter.showDebug()
        }
        else if indexPath.isEpochDateRow {
            // This delay is purely aesthetic, give the highlight enough time to
            // be seen before dismissing it.
            Dispatch.toForegroundAfter(milliseconds: 100) {
                self.edittingDate.toggle()
                self.refreshRowHeights()
            }
        }
    }
}
