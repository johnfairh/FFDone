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
}

/// VC for alarm create/edit
class AlarmEditViewController: PresentableBasicTableVC<AlarmEditPresenterInterface>, UITextFieldDelegate {

    // MARK: Controls

    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var repeatsLabel: UILabel!
    @IBOutlet weak var repeatDayLabel: UILabel!

    // overly complicated table state
    private var weekdayNumber: Int?
    private var canEditRepeat: Bool = false

    private func dayName(weekday: Int) -> String {
        return Calendar.current.weekdaySymbols[weekday - 1]
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        nameTextField.delegate = self

        presenter.refresh = { [unowned self] alarm, isSaveOK, isEditRepeatOK in
            self.doneButton.isEnabled = isSaveOK
            self.canEditRepeat = isEditRepeatOK
            self.nameTextField.text = alarm.name
            self.iconImageView.image = alarm.nativeImage
            self.repeatsLabel.text = alarm.kind.repeatText
            self.weekdayNumber = alarm.kind.repeatDay
            if let day = self.weekdayNumber {
                self.repeatDayLabel.text = self.dayName(weekday: day)
            }
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

    // Close the keyboard when appropriate, plus listen live for changes
    // to the fields and update everything, sanitizing the step entries.
    //
    // Autocomplete the tag field against existing tags.

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @IBAction func nameTextFieldDidChange(_ sender: UITextField) {
        presenter.setName(name: sender.text!)
    }

    // MARK: Table stuff

    func refreshRowHeights() {
//        Dispatch.toForeground {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
//        }
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
        return indexPath.isIconRow || (canEditRepeat && (indexPath.isRepeatRow || indexPath.isRepeatDayRow))
    }

    /// Trigger the icon picker
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.isIconRow {
            presenter.pickIcon()
        } else if indexPath.isRepeatRow {
            let kinds: [Alarm.Kind] = [.oneShot, .weekly(3), .daily]
            let choices = kinds.map { $0.repeatText }
            presentActionSheetChoice(choices: choices, results: kinds) { kind in
                if let kind = kind {
                    tableView.deselectRow(at: indexPath, animated: true)
                    self.presenter.setKind(kind: kind)
                }
            }
        } else if indexPath.isRepeatDayRow {
            let choices = Calendar.current.weekdaySymbols
            let results = Array(1...7)
            presentActionSheetChoice(choices: choices, results: results) { dayNumber in
                if let dayNumber = dayNumber {
                    tableView.deselectRow(at: indexPath, animated: true)
                    self.presenter.setKind(kind: .weekly(dayNumber))
                }
            }
        }
    }
}
