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
@MainActor
final class AlarmScheduler: NSObject, UNUserNotificationCenterDelegate {
    private let center: UNUserNotificationCenter
    private var model: Model?
    private var authorized = false

    init(app: App) {
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

        /// Called from App when we are ready to go.
        app.notifyWhenReady { model in
            self.model = model
            self.scan()
        }
    }

    /// Called from App when we are about to come into the foreground having been away for a while
    func willEnterForeground() {
        scan()
    }

    /// Called when an Alarm is deactivated and we know when to reactivate it.
    /// Callback is made with the string uuid of the alarm or `nil` if it didn't work.
    func scheduleAlarm(text: String, image: UIImage, for date: Date) async -> String? {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            Log.log("AlarmScheduler: Not authorized to schedule, bailing")
            return nil
        }
        if settings.alertSetting != .enabled {
            Log.log("AlarmScheduler: Auth OK but alerts disabled?  Continuing.")
        }

        let content = UNMutableNotificationContent(text: text, image: image)
        let request = UNNotificationRequest(content: content, date: date)
        return await center.addNotifyIdentifier(request)
    }

    /// Called when a deactivated alarm is deleted.  Best effort, asynchronous, etc.
    func cancelAlarm(uid: String) {
        center.removePendingNotificationRequests(withIdentifiers: [uid])
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        Task { await scan() }
        completionHandler(.banner)
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
        UIApplication.shared.applicationIconBadgeNumber
    }

    func setActiveAlarmCount(_ newCount: Int) async {
        guard badgesEnabled, newCount != activeAlarmCount else {
            return
        }
        UIApplication.shared.applicationIconBadgeNumber = newCount

        let requests = await center.pendingNotificationRequests()
        Log.log("Scanning notifications")

        for (index, request) in requests.sortedByCalendarTrigger.enumerated() {
            // When this, the Nth nf, fires, badge should be the current value
            // (number of active alarms) plus N.
            let newBadge = newCount + index + 1
            let currentBadge = (request.content.badge as? Int) ?? Int.max

            guard currentBadge != newBadge else {
                Log.log("Request already has the right badge")
                return
            }

            Log.log("Adding replacement notification, \(currentBadge) -> \(newBadge)")
            await center.addNotifyIdentifier(request.clone(badge: newBadge))
        }
    }

    func hideBadges() async {
        Log.assert(!badgesEnabled)
        UIApplication.shared.applicationIconBadgeNumber = 0 // disabled
        let requests = await center.pendingNotificationRequests()
        for request in requests {
            await center.addNotifyIdentifier(request.clone(badge: nil))
        }
    }
}

fileprivate var badgesEnabled: Bool {
    Prefs.subbed
}

// MARK: NotificationCenter helpers

extension UNUserNotificationCenter {
    /// Add a notification, optionally call back with identifier on FG queue, log
    @discardableResult
    func addNotifyIdentifier(_ request: UNNotificationRequest) async -> String? {
        do {
            try await add(request)
            return request.identifier
        } catch {
            Log.log("AlarmScheduler: add request failed: \(error)")
            return nil
        }
    }
}

// MARK: Notification creation and cloing

extension UNNotificationContent {
    /// Get a version of the content with a different `badge` value
    func clone(badge: Int? = nil) -> UNMutableNotificationContent {
        let newContent = UNMutableNotificationContent()
        newContent.title = title
        newContent.body = body
        newContent.badge = badge.flatMap { $0 as NSNumber }
        if let oldAttachment = attachments.first {
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
        return newContent
    }
}

extension UNMutableNotificationContent {
    /// New FFDone notification content, badge '1'
    convenience init(text: String, image: UIImage) {
        self.init()

        title = "Not done yet"
        body = text
        if badgesEnabled {
            // Calculating the badge at this point is too hard: we'd have to examine the entire
            // pending list and insert this new guy, updating the badge count of those that
            // follow. Instead we set an arbitrary value and wait for the DB update that will
            // follow and that will call `setActiveAlarmCount()` to keep the app and tab badges
            // in sync.  Relying on the only code path getting here being moving an existing
            // Alarm object from active to scheduled.
            badge = 1
        }
        categoryIdentifier = Strings.Notification.Category

        // Try to add the alert's image to the notification.  The UN system moves
        // the file over into the notifications area, so don't delete it.
        let imageFileUrl = FileManager.default.temporaryFileURL(extension: "png")
        Log.log("Orig: \(imageFileUrl.path)")
        if let pngImageData = image.pngData() {
            do {
                try pngImageData.write(to: imageFileUrl)
                let attachment = try UNNotificationAttachment(identifier: UUID().uuidString, url: imageFileUrl)
                attachments = [attachment]
            } catch {
                Log.log("Failed to create notification PNG, pressing on - \(error)")
            }
        }
    }
}

extension UNNotificationRequest {
    /// New one-shot notification with content
    convenience init(content: UNNotificationContent, date: Date) {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        self.init(identifier: UUID().uuidString, content: content, trigger: trigger)
    }

    /// Get a version of the request with a different `content.badge` value
    func clone(badge: Int? = nil) -> UNNotificationRequest {
        UNNotificationRequest(identifier: identifier,
                              content: content.clone(badge: badge),
                              trigger: trigger)
    }
}

// MARK: Notification sorting

extension Array where Element == UNNotificationRequest {
    /// Sorted in order that the notifications will fire
    var sortedByCalendarTrigger: Self {
        sorted { left, right in
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
    }
}
