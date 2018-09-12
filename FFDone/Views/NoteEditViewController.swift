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

        // XXX start temp coloring
        textView.textColor = .text
        goalNameButton.setTitleColor(.text, for: .normal)
        dateLabel.textColor = .text
        view.backgroundColor = .black
        view.tintColor = .tint
        // XXX end temp coloring

        textView.text = presenter.text
        dateLabel.text = presenter.date
        if let goal = presenter.goal {
            goalImageView.image = goal.nativeImage
            goalNameButton.setTitle(goal.name, for: .normal)
        } else {
            goalImageView.isHidden = true
            goalNameButton.isHidden = true
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
        presenter.showGoal()
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
