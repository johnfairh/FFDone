//
//  IconEditViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// VC for icon edit
class IconEditViewController: PresentableVC<IconEditPresenterInterface>, UITextFieldDelegate, IconSourceDelegate {
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var iconImageView: UIImageView!

    @IBOutlet weak var firstSourceLabel: UILabel!
    @IBOutlet weak var firstSourceTextField: UITextField!
    @IBOutlet weak var firstSourceButton: UIButton!

    @IBOutlet weak var secondSourceLabel: UILabel!
    @IBOutlet weak var secondSourceTextField: UITextField!
    @IBOutlet weak var secondSourceButton: UIButton!

    var iconSources: [IconSource]?

    var hasIcon: Bool = false

    static let unknownIconImage = UIImage(named: "UnknownIcon")
    static let errorIconImage = UIImage(named: "ErrorIcon")

    override func viewDidLoad() {
        iconImageView.image = IconEditViewController.unknownIconImage
        nameTextField.delegate = self

        let firstSourceUI = IconSourceUI(label: firstSourceLabel,
                                         textField: firstSourceTextField,
                                         button: firstSourceButton)
        let secondSourceUI = IconSourceUI(label: secondSourceLabel,
                                          textField: secondSourceTextField,
                                          button: secondSourceButton)

        iconSources = IconSourceBuilder.createSources(uiList: [firstSourceUI, secondSourceUI],
                                                      delegate: self)
        updateControls()
        firstSourceTextField.becomeFirstResponder()
    }

    // Update button states based on content
    func updateControls() {
        if let doneBarButton = navigationItem.rightBarButtonItem {
            doneBarButton.isEnabled = (!newIconName.isEmpty && hasIcon)
        }
    }

    // MARK: - IconSourceDelegate interface

    func setIconImage(iconSource: IconSource, image: UIImage) {
        hasIcon = true
        iconImageView.image = image
        if newIconName.isEmpty {
            if iconSource.textIsSuitableIconName {
                nameTextField.text = iconSource.text
            } else {
                nameTextField.becomeFirstResponder()
            }
        }
        updateControls()
    }

    func setIconError(iconSource: IconSource, message: String) {
        hasIcon = false
        iconImageView.image = IconEditViewController.errorIconImage
        Log.log(message)
        updateControls()
    }

    // MARK: - Name text field

    var newIconName: String {
        return nameTextField.text ?? ""
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        updateControls()
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // MARK: - Bar buttons

    @IBAction func didTapCancelButton(_ sender: UIBarButtonItem) {
        iconSources?.cancel()
        presenter.cancel()
    }

    @IBAction func didTapDoneButton(_ sender: UIBarButtonItem) {
        presenter.save(name: newIconName, image: iconImageView.image!)
    }
}
