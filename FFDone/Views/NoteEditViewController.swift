//
//  NoteEditViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// VC for note edit
class NoteEditViewController: PresentableVC<NoteEditPresenterInterface> {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var goalImageView: UIImageView!
    @IBOutlet weak var goalNameButton: UIButton!
    @IBOutlet weak var dateLabel: UILabel!
    
    // MARK: - Functional stuff

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        setBasicColors()
        dateLabel.setColors()
        goalNameButton.setColors()

        textView.text = presenter.text
        dateLabel.text = presenter.date
        goalNameButton.setTitle(presenter.ownerName, for: .normal)
        if let icon = presenter.ownerIcon {
            goalImageView.image = icon.nativeImage
        } else {
            goalImageView.isHidden = true
            navigationItem.title = "New Note"
        }
        if textView.text.isEmpty {
            textView.becomeFirstResponder()
        }
    }

    @IBAction func cancelButtonDidTap(_ sender: UIBarButtonItem) {
        presenter.cancel()
    }

    @IBAction func doneButtonDidTap(_ sender: UIBarButtonItem) {
        presenter.save(text: textView.text)
    }

    @IBAction func goalButtonDidTap(_ sender: Any) {
        presenter.showOwner()
    }
    
    // MARK: - Keyboard dance :-(

    private var keyboardShowListener: NotificationListener?
    private var keyboardHideListener: NotificationListener?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        keyboardShowListener = NotificationListener(name: UIResponder.keyboardDidShowNotification, from: nil, callback: keyboardDidShow)
        keyboardHideListener = NotificationListener(name: UIResponder.keyboardWillHideNotification, from: nil, callback: keyboardWillHide)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardShowListener?.stopListening()
        keyboardHideListener?.stopListening()
        keyboardShowListener = nil
        keyboardHideListener = nil
    }

    func keyboardDidShow(_ notification: Notification) {
        guard let info = (notification as NSNotification).userInfo,
            let kbRectValue = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
                Log.fatal("Confused about keyboard show notification")
        }

        let kbRect = kbRectValue.cgRectValue
        let kbHeight = UIScreen.main.bounds.size.height - kbRect.origin.y

        let newInsets = UIEdgeInsets(top: 0, left: 0, bottom: kbHeight, right: 0)
        textView.contentInset = newInsets
        textView.scrollIndicatorInsets = newInsets
    }

    func keyboardWillHide(_ notification: Notification) {
        textView.contentInset = .zero
        textView.scrollIndicatorInsets = .zero
    }
}
