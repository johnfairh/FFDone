//
//  DebugViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// VC for the debug view
class DebugViewController: PresentableVC<DebugPresenterInterface>, UITextFieldDelegate {

    @IBOutlet weak var commandTextField: UITextField!
    @IBOutlet weak var textTextView: UITextView!

    override public func viewDidLoad() {
        super.viewDidLoad()

        commandTextField.delegate = self
        textTextView.isEditable = false

        presenter.refresh = { [unowned self] debugData in
            self.textTextView.text = debugData.text
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        presenter.close()
        super.viewWillDisappear(animated)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        presenter.doCommand(cmd: textField.text!)
        textField.resignFirstResponder()
        return true
    }

    @IBAction func clearButtonTapped(_ sender: UIButton) {
        presenter.clear()
    }


    @IBAction func logButtonTapped(_ sender: UIButton) {
        presenter.showLog()
    }

    @IBAction func notificationsButtonTapped(_ sender: UIButton) {
        presenter.showNotifications()
    }
}
