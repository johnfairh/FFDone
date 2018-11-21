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

        center.requestAuthorization(options: [.alert, .badge]) { granted, error in
            if !granted {
                Log.log("Notification authorization denied")
                if let error = error {
                    Log.log("  error report: \(error)")
                }
            }
            self.authorized = granted
        }

        let category = UNNotificationCategory(identifier: Strings.Notification.Category,
                                              actions: [],
                                              intentIdentifiers: [],
                                              hiddenPreviewsBodyPlaceholder: "%u alarms")
        center.setNotificationCategories([category])
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
            // Calculating the badge at this point is tricky - we have to examine the entire
            // pending list and insert this new guy (which will require the tail of said list
            // to also be updated).  So instead we set an arbitrary value and wait for the DB
            // update that will follow this schedule() that will update the `activeAlarmCount`
            // variable to keep the app and tab badges in sync.
            content.badge = 1
            content.categoryIdentifier = Strings.Notification.Category

            // Try to add the alert's image to the notification.  The UN system moves
            // the file over into the notifications area, so don't delete it.
            let imageFileUrl = FileManager.default.temporaryFileURL(extension: "png")
            Log.log("Orig: \(imageFileUrl.path)")
            if let pngImageData = image.pngData() {
                do {
                    try pngImageData.write(to: imageFileUrl)

                    let attachment = try UNNotificationAttachment(identifier: UUID().uuidString, url: imageFileUrl)
                    content.attachments = [attachment]
                } catch {
                    Log.log("Failed to create notification PNG, pressing on - \(error)")
                }
            }

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let uid = UUID().uuidString
            let request = UNNotificationRequest(identifier: uid, content: content, trigger: trigger)

            self.center.add(request) { error in
                Log.log("Notification added OK")
                Dispatch.toForeground {
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

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
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

    // MARK: - Badge maintenance

    // This is very complicated because the notification object needs to know the absolute
    // value of the app badge that it should display -- there is no "just increment the
    // number that is already there" which would 100% meet our needs.
    //
    // So whenever the active alarm count changes, we have to scan through the queue of
    // notification requests and update them all.
    //
    // This might be racy -- it's not clear whether calls to `getPendingNotificationRequests`
    // are serialized.  Probably would be better to bounce back onto the private queue.
    var activeAlarmCount: Int {
        get {
            return UIApplication.shared.applicationIconBadgeNumber
        }
        set {
            guard newValue != activeAlarmCount else {
                Log.log("SetActiveAlarmCount \(newValue): skipping, same")
                return
            }
            UIApplication.shared.applicationIconBadgeNumber = newValue

            center.getPendingNotificationRequests { [activeAlarmCount] requests in
                guard requests.count > 0 else {
                    return
                }

                Log.log("Scanning notifications")

                // Get notifications into the order they will fire
                let sortedRequests = requests.sorted { left, right in
                    guard let leftTrigger = left.trigger,
                        let leftCalendarTrigger = leftTrigger as? UNCalendarNotificationTrigger,
                        let leftTriggerDate = leftCalendarTrigger.nextTriggerDate(),
                        let rightTrigger = right.trigger,
                        let rightCalendarTrigger = rightTrigger as? UNCalendarNotificationTrigger,
                        let rightTriggerDate = rightCalendarTrigger.nextTriggerDate() else {
                            Log.fatal("Weird notification in the queue: \(left), \(right)")
                    }

                    return leftTriggerDate < rightTriggerDate
                }

                // Get the list of badges in the same order
                let badgeNumbers = (activeAlarmCount+1)...(activeAlarmCount + sortedRequests.count)

                // Look for things that need changing
                zip(sortedRequests, badgeNumbers).forEach { request, newBadge in
                    guard let currentBadgeValue = request.content.badge,
                        let currentBadge = currentBadgeValue as? Int else {
                            Log.log("Weird notification in the queue: \(request), pressing on...")
                            return
                    }

                    guard currentBadge != newBadge else {
                        Log.log("Request already has the right badge")
                        return
                    }

                    // Replace the notification
                    let newContent = UNMutableNotificationContent()
                    newContent.title = request.content.title
                    newContent.body = request.content.body
                    newContent.badge = newBadge as NSNumber
                    if let oldAttachment = request.content.attachments.first {
                        let oldUrl = oldAttachment.url
                        let tmpUrl = FileManager.default.temporaryFileURL(extension: "png")
                        Log.log("Previous url: \(oldUrl.path)")
                        Log.log("New tmp url: \(tmpUrl.path)")
                        if oldUrl.startAccessingSecurityScopedResource() {
                            defer { oldUrl.stopAccessingSecurityScopedResource() }
                            do {
                                try FileManager.default.copyItem(at: oldUrl, to: tmpUrl)
                                let newAttachment = try UNNotificationAttachment(identifier: UUID().uuidString, url: tmpUrl)
                                newContent.attachments = [newAttachment]
                            } catch {
                                Log.log("Copying up attachment failed: \(error)")
                            }
                        } else {
                            Log.log("Can't get security access to copy up attachment")
                        }
                    }
                    newContent.categoryIdentifier = Strings.Notification.Category

                    Log.log("Adding replacement notification, \(currentBadge) -> \(newBadge)")

                    let newRequest = UNNotificationRequest(identifier: request.identifier, content: newContent, trigger: request.trigger)
                    self.center.add(newRequest) { error in
                        Log.log("Replacement notification added")
                        if let error = error {
                            Log.log("Error trying to replace notification: \(error), pressing on...")
                        }
                    }
                }
            }
        }
    }
}
