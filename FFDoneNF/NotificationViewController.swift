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
                defer { attachment.url.stopAccessingSecurityScopedResource() }

                do {
                    /* So: the UIImage constructor that takes a URL is a trap, it does
                     * lazy loading of the image data which escapes this security
                     * access block and does nothing.
                     */
                    let imageData = try Data(contentsOf: attachment.url)
                    if let loadedImage = UIImage(data: imageData) {
                        image.image = loadedImage
                        image.sizeToFit()
                    }
                } catch {
                    // For the life of me can't debug these issues....
                    // detailLabel.text = "e: no img load"
                }
            } else {
                detailLabel.text = "e: no security"
            }
        } else {
            detailLabel.text = "e: no attachment"
        }
    }
}
