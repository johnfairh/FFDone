//
//  IconEditViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// VC for icon edit
class IconEditViewController: PresentableVC<IconEditPresenterInterface>,
                              UITextFieldDelegate,
                              IconSourceDelegate {
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var iconImageView: UIImageView!

    @IBOutlet weak var firstSourceLabel: UILabel!
    @IBOutlet weak var firstSourceTextField: UITextField!
    @IBOutlet weak var firstSourceButton: UIButton!

    @IBOutlet weak var secondSourceLabel: UILabel!
    @IBOutlet weak var secondSourceTextField: UITextField!
    @IBOutlet weak var secondSourceButton: UIButton!

    var iconSources: [IconSource]?

    static let unknownIconImage = UIImage(named: "UnknownIcon")
    static let errorIconImage = UIImage(named: "ErrorIcon")

    override func viewDidLoad() {
        super.viewDidLoad()

        // XXX start temp color stuff
        view.backgroundColor = .background
        view.tintColor = .tint
        firstSourceLabel.textColor = .text
        secondSourceLabel.textColor = .text
        nameTextField.backgroundColor = .background
        UITextField.appearance(whenContainedInInstancesOf: [IconEditViewController.self]).backgroundColor = .background
        UITextField.appearance(whenContainedInInstancesOf: [IconEditViewController.self]).textColor = .text
        // XXX end temp color stuff

        nameTextField.delegate = self
        iconImageView.enableRoundCorners()

        let firstSourceUI = IconSourceUI(label: firstSourceLabel,
                                         textField: firstSourceTextField,
                                         button: firstSourceButton)
        let secondSourceUI = IconSourceUI(label: secondSourceLabel,
                                          textField: secondSourceTextField,
                                          button: secondSourceButton)

        iconSources = IconSourceBuilder.createSources(uiList: [firstSourceUI, secondSourceUI],
                                                      delegate: self)

        presenter.refresh = { [unowned self] icon, canSave in
            self.nameTextField.text = icon.name ?? ""
            if icon.hasImage {
                self.iconImageView.image = icon.nativeImage
            } else if self.iconImageView.image != IconEditViewController.errorIconImage {
                self.iconImageView.image = IconEditViewController.unknownIconImage
            }
            if let doneBarButton = self.navigationItem.rightBarButtonItem {
                doneBarButton.isEnabled = canSave
            }
        }
        firstSourceTextField.becomeFirstResponder()
    }

    // MARK: - IconSourceDelegate interface

    func setIconImage(iconSource: IconSource, image: UIImage) {
        presenter.setImage(image: image)
        if newIconName.isEmpty {
            if iconSource.textIsSuitableIconName {
                presenter.setName(name: iconSource.text)
            } else {
                nameTextField.becomeFirstResponder()
            }
        }
    }

    func setIconError(iconSource: IconSource, message: String) {
        iconImageView.image = IconEditViewController.errorIconImage
        presenter.clearImage()
        Log.log(message)
    }

    // MARK: - Name text field

    var newIconName: String {
        return nameTextField.text ?? ""
    }

    @IBAction func nameTextFieldDidChange(_ sender: UITextField) {
        presenter.setName(name: newIconName)
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
        presenter.save()
    }
}
