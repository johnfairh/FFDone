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

    // overly complicated table state

    public override func viewDidLoad() {
        super.viewDidLoad()

//        nameTextField.delegate = self

        presenter.refresh = { [unowned self] epoch, isSaveOK in
            doneButton.isEnabled = isSaveOK
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
}

