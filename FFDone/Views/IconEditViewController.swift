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

    @IBOutlet weak var defaultGoalLabel: UILabel!
    @IBOutlet weak var defaultGoalSwitch: UISwitch!
    @IBOutlet weak var defaultAlarmLabel: UILabel!
    @IBOutlet weak var defaultAlarmSwitch: UISwitch!

    var iconSources: [IconSource]?

    static let unknownIconImage = UIImage(named: "UnknownIcon")
    static let errorIconImage = UIImage(named: "ErrorIcon")

    override func viewDidLoad() {
        super.viewDidLoad()

        setBasicColors()
        firstSourceLabel.setColors()
        secondSourceLabel.setColors()
        defaultGoalLabel.setColors()
        defaultAlarmLabel.setColors()
        // we use odd style of text fields here..
        UITextField.appearance(whenContainedInInstancesOf: [IconEditViewController.self]).backgroundColor = .background

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

        presenter.refresh = { [unowned self] icon, goalDefault, alarmDefault, canSave in
            self.nameTextField.text = icon.name ?? ""
            if icon.hasImage {
                self.iconImageView.image = icon.nativeImage
            } else if self.iconImageView.image != IconEditViewController.errorIconImage {
                self.iconImageView.image = IconEditViewController.unknownIconImage
            }
            if let doneBarButton = self.navigationItem.rightBarButtonItem {
                doneBarButton.isEnabled = canSave
            }
            self.defaultGoalSwitch.setOn(goalDefault, animated: false)
            self.defaultAlarmSwitch.setOn(alarmDefault, animated: false)
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

    // MARK: - Defaults switches
    
    @IBAction func defaultGoalDidChange(_ sender: UISwitch) {
        presenter.setGoalDefault(value: sender.isOn)
    }

    @IBAction func defaultAlarmDidChange(_ sender: UISwitch) {
        presenter.setAlarmDefault(value: sender.isOn)
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
