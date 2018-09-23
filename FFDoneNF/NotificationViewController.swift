//
//  NotificationViewController.swift
//  FFDoneNF
//
//  Distributed under the MIT license, see LICENSE.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var image: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        image.layer.cornerRadius = 6
        image.layer.masksToBounds = true
    }
    
    func didReceive(_ notification: UNNotification) {
        let content = notification.request.content
        titleLabel.text = content.title
        detailLabel.text = content.body
        if let attachment = content.attachments.first {
            if attachment.url.startAccessingSecurityScopedResource() {
                if let loadedImage = UIImage(contentsOfFile: attachment.url.path) {
                    image.image = loadedImage
                    image.sizeToFit()
                } else {
                    detailLabel.text = "e: no img load"
                }
                attachment.url.stopAccessingSecurityScopedResource()
            } else {
                detailLabel.text = "e: no security"
            }
        } else {
            detailLabel.text = "e: no attachment"
        }
    }
}
