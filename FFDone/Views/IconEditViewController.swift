//
//  IconEditViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// VC for icon edit
class IconEditViewController: PresentableVC<IconEditPresenterInterface>,
                              UITextFieldDelegate {
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

    var iconSourceControllers: [IconSourceViewController] = []

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

        iconSourceControllers.append(IconSourceViewController(label: firstSourceLabel,
                                                              textField: firstSourceTextField,
                                                              button: firstSourceButton))
        iconSourceControllers.append(IconSourceViewController(label: secondSourceLabel,
                                                              textField: secondSourceTextField,
                                                              button: secondSourceButton))

        zip(iconSourceControllers, IconSourceBuilder.sources).forEach {[unowned self] ui, source in
            ui.label.text = source.name
            ui.textField.placeholder = source.inputDescription
            ui.textEntryCallback = { text in
                source.cancel()
                source.findIcon(name: text) { result in
                    switch result {
                    case .success(let image):
                        self.setIconImage(image: image, name: ui.text)
                    case .failure(let error):
                        self.setIconError(message: error.text)
                    }
                }
            }
        }

        presenter.refresh = { [unowned self] m in
            self.nameTextField.text = m.icon.name ?? ""
            if m.icon.hasImage {
                self.iconImageView.image = m.icon.nativeImage
            } else if self.iconImageView.image != IconEditViewController.errorIconImage {
                self.iconImageView.image = IconEditViewController.unknownIconImage
            }
            if let doneBarButton = self.navigationItem.rightBarButtonItem {
                doneBarButton.isEnabled = m.canSave
            }
            self.defaultGoalSwitch.setOn(m.isGoalDefault, animated: false)
            self.defaultAlarmSwitch.setOn(m.isAlarmDefault, animated: false)
        }
        firstSourceTextField.becomeFirstResponder()
    }

    // MARK: - IconSource completion

    func setIconImage(image: UIImage, name: String) {
        presenter.setImage(image: image)
        if newIconName.isEmpty {
            presenter.setName(name: name)
        }
    }

    func setIconError(message: String) {
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
        IconSourceBuilder.cancelAll()
        presenter.cancel()
    }

    @IBAction func didTapDoneButton(_ sender: UIBarButtonItem) {
        IconSourceBuilder.cancelAll()
        presenter.save()
    }
}

/// Handle one set of icon-fetching UI
class IconSourceViewController: NSObject, UITextFieldDelegate {
    weak var label: UILabel!
    weak var textField: UITextField!
    weak var button: UIButton!
    var textEntryCallback: (String) -> Void = { _ in }

    init(label: UILabel, textField: UITextField, button: UIButton) {
        self.label = label
        self.textField = textField
        self.button = button
        super.init()

        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        textField.delegate = self
        update()
    }

    var text: String {
        return textField.text ?? ""
    }

    /// Refresh control enable state
    private func update() {
        button.isEnabled = !text.isEmpty
    }

    /// Text field delegate: return key prompts fetch
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if !text.isEmpty {
            Dispatch.toForeground {
                self.buttonTapped(self.button)
            }
        }
        textField.resignFirstResponder()
        return true
    }

    /// Text field delegate: refresh UI
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        update()
        return true
    }

    /// Buttonpress - cancel any active fetch and start a new one
    @objc func buttonTapped(_ sender: UIButton) {
        textEntryCallback(text)
    }
}
