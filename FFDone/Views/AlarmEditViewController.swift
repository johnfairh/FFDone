//
//  AlarmEditViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Hard-code a bit of knowledge about the dialog static table layout
private extension IndexPath {
    var isIconRow: Bool {
        return section == 0 && row == 1
    }

    var isRepeatRow: Bool {
        return section == 0 && row == 2
    }

    var isRepeatDayRow: Bool {
        return section == 0 && row == 3
    }

    var isDefaultNotesRow: Bool {
        return section == 0 && row == 4
    }

    var isNotesRow: Bool {
        return section == 1 && row == 0
    }
}

/// VC for alarm create/edit
class AlarmEditViewController: PresentableBasicTableVC<AlarmEditPresenterInterface>, UITextFieldDelegate {

    // MARK: Controls

    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var repeatsLabel: UILabel!
    @IBOutlet weak var repeatDayLabel: UILabel!
    @IBOutlet weak var activeNotesLabel: UILabel!

    // overly complicated table state
    private var weekdayNumber: Int?
    private var canEditRepeat: Bool = false

    private func dayName(weekday: Int) -> String {
        return Calendar.current.weekdaySymbols[weekday - 1]
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        nameTextField.delegate = self

        presenter.refresh = { [unowned self] alarm, isSaveOK in
            self.doneButton.isEnabled = isSaveOK
            self.canEditRepeat = alarm.isActive
            self.nameTextField.text = alarm.name
            self.iconImageView.image = alarm.nativeImage
            self.repeatsLabel.text = alarm.kind.repeatText
            self.weekdayNumber = alarm.kind.repeatDay
            if let day = self.weekdayNumber {
                self.repeatDayLabel.text = self.dayName(weekday: day)
            }
            self.activeNotesLabel.text = alarm.notes
            self.refreshRowHeights()
        }
    }

    // MARK: Simple control reactions

    @IBAction func cancelButtonDidTap(_ sender: UIBarButtonItem) {
        presenter.cancel()
    }

    @IBAction func doneButtonDidTap(_ sender: UIBarButtonItem) {
        presenter.save()
    }

    // MARK: Text stuff

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @IBAction func nameTextFieldDidChange(_ sender: UITextField) {
        presenter.setName(name: sender.text!)
    }

    // MARK: Table stuff

    func refreshRowHeights() {
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    /// Hide the disclosure triangle if can't edit those rows
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if !canEditRepeat {
            if indexPath.isRepeatDayRow || indexPath.isRepeatRow {
                cell.accessoryType = .none
            }
        }
        return cell
    }

    /// Hide the 'repeat day' row unless we are repeating weekly
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.isRepeatDayRow && weekdayNumber == nil {
            return 0
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }

    /// Allow rows that do stuff to highlight
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.isIconRow ||
            (canEditRepeat && (indexPath.isRepeatRow || indexPath.isRepeatDayRow)) ||
            indexPath.isDefaultNotesRow || indexPath.isNotesRow
    }

    /// Trigger a picker for things that need to be picked
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.isIconRow {
            presenter.pickIcon()
        } else if indexPath.isRepeatRow {
            let kinds: [Alarm.Kind] = [.oneShot, .weekly(3), .dailyReset, .dailyGc]
            let choices = kinds.map { $0.repeatText }
            presentActionSheetChoice(choices: choices, results: kinds) { kind in
                tableView.deselectRow(at: indexPath, animated: true)
                if let kind = kind {
                    self.presenter.setKind(kind: kind)
                }
            }
        } else if indexPath.isRepeatDayRow {
            let choices = Calendar.current.weekdaySymbols
            let results = Array(1...7)
            presentActionSheetChoice(choices: choices, results: results) { dayNumber in
                tableView.deselectRow(at: indexPath, animated: true)
                if let dayNumber = dayNumber {
                    self.presenter.setKind(kind: .weekly(dayNumber))
                }
            }
        } else if indexPath.isDefaultNotesRow {
            presenter.editDefaultNotes()
        } else if indexPath.isNotesRow {
            presenter.editActiveNotes()
        }
    }
}
