//
//  EpochEditViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//
import TMLPresentation

/// VC for alarm create/edit
class EpochEditViewController: PresentableBasicTableVC<EpochEditPresenterInterface>, UITextFieldDelegate {

    // MARK: Controls
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var longNameTextField: UITextField!
    @IBOutlet weak var shortNameTextField: UITextField!
    @IBOutlet weak var versionTextField: UITextField!
    
    // Table state
    private var epochDate: String!

    public override func viewDidLoad() {
        super.viewDidLoad()

        longNameTextField.delegate = self
        shortNameTextField.delegate = self
        versionTextField.delegate = self

        longNameTextField.becomeFirstResponder()

        presenter.refresh = { [unowned self] epoch, isSaveOK in
            doneButton.isEnabled = isSaveOK
            longNameTextField.text = epoch.longName
            shortNameTextField.text = epoch.shortName
            if epoch.majorVersion != 0 || epoch.minorVersion != 0 {
                versionTextField.text = epoch.versionText
            }
            epochDate = epoch.startDateText
        }
    }

    public override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView,
           let label = headerView.textLabel,
           let epochDate = self.epochDate {
            label.text = epochDate
        }
    }

    // MARK: Simple control reactions

    @IBAction func cancelButtonDidTap(_ sender: UIBarButtonItem) {
        presenter.cancel()
    }

    @IBAction func doneButtonDidTap(_ sender: UIBarButtonItem) {
        presenter.save()
    }

    @IBAction func textFieldDidChange(_ sender: UITextField) {
        let text = sender.text ?? ""
        switch sender {
        case longNameTextField:
            presenter.set(longName: text)
        case shortNameTextField:
            presenter.set(shortName: text)
        case versionTextField:
            presenter.set(versionString: text)
        default:
            break
        }
    }

    // MARK: Text stuff

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

