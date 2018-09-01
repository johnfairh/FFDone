//
//  AlarmScheduler.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation
import UserNotifications

/// This is the interface to UserNotifications that is used to generate local notifications
/// for alarms as well as actually make the alarmed events activate.
///
/// We do not expect to operate on a particularly large scale.
/// So we just have one bulk scan operation that finds and reactivates all
/// the alarms that need it.
///
/// And we invoke this scan from appropriate places:
/// 1. when the app starts
/// 2. when the app comes into the foreground
/// 3. when a notification is delivered.
///
/// We don't bother with any local timers so if notifications are disabled
/// then alarms will stop reactivating.  Oh well.
///
final class AlarmScheduler: NSObject, UNUserNotificationCenterDelegate {
    private let center: UNUserNotificationCenter
    private var model: Model?
    private var authorized = false

    override init() {
        center = UNUserNotificationCenter.current()
        super.init()

        center.delegate = self

        center.requestAuthorization(options: [.alert]) { granted, error in
            if !granted {
                Log.log("Notification authorization denied")
                if let error = error {
                    Log.log("  error report: \(error)")
                }
            }
            self.authorized = granted
        }
    }

    /// Called from App when we are ready to go.
    func modelIsReady(model: Model) {
        self.model = model.createChildModel(background: true)
        scan()
    }

    /// Called from App when we are about to come into the foreground having been away for a while
    func willEnterForeground() {
        scan()
    }

    /// Called when an Alarm is deactivated and we know when to reactivate it.
    /// Callback is made with the string uuid of the alarm or `nil` if it didn't work.
    func scheduleAlarm(text: String, image: UIImage, for date: Date, callback: @escaping (String?) -> Void) {
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                Log.log("AlarmScheduler: Not authorized to schedule, bailing")
                return
            }
            if settings.alertSetting != .enabled {
                Log.log("AlarmScheduler: Auth OK but alerts disabled?  Continuing.")
            }

            let content = UNMutableNotificationContent()
            content.title = "Not done yet"
            content.body = text

            // Try to add the alert's image to the notification
            let imageFileUrl = FileManager.default.temporaryFileURL(extension: "png")
            if let pngImageData = image.pngData() {
                do {
                    try pngImageData.write(to: imageFileUrl)

                    let attachment = try UNNotificationAttachment(identifier: "???", url: imageFileUrl)
                    content.attachments = [attachment]
                } catch {
                    Log.log("Failed to create notification PNG, pressing on - \(error)")
                }
            }

            let interval = date.timeIntervalSinceNow
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)

            let uid = UUID().uuidString
            let request = UNNotificationRequest(identifier: uid, content: content, trigger: trigger)

            self.center.add(request) { error in
                Dispatch.toForeground {
                    try? FileManager.default.removeItem(at: imageFileUrl)
                    if let error = error {
                        Log.log("AlarmScheduler: add request failed: \(error)")
                        callback(nil)
                    } else {
                        callback(uid)
                    }
                }
            }
        }
    }

    /// Called when a deactivated alarm is deleted.  Best effort, asynchronous, etc.
    func cancelAlarm(uid: String) {
        center.removePendingNotificationRequests(withIdentifiers: [uid])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        scan() // this runs async, not finished by time next line runs
        completionHandler(.alert)
    }

    // MARK: - Alert database inteface

    private func scan() {
        // Switch onto our private model's queue
        model?.perform { model in
            let alarms = Alarm.findDueAlarms(model: model)
            alarms.forEach { alarm in
                Log.log("Activating alarm \(alarm.text)")
                alarm.activate()
            }
            model.save()
        }
    }
}
