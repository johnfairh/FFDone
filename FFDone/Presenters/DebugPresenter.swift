//
//  DebugPresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation
import UserNotifications

struct DebugData {
    var text: String
}

/// Presenter inputs, commands, outputs
@MainActor
protocol DebugPresenterInterface {
    /// Get told about data changes
    var refresh: (DebugData) -> Void { get set }

    /// Clear data
    func clear()

    /// Show the log data
    func showLog()

    /// Show notifications status
    func showNotifications()

    /// Issue a custom command
    func doCommand(cmd: String)

    /// Going offscreen
    func close()
}

class DebugPresenter: Presenter, DebugPresenterInterface {
    typealias ViewInterfaceType = DebugPresenterInterface

    private let model: Model
    private let director: DirectorInterface
    private let dismiss: PresenterDone<Goal>

    private var data: DebugData {
        didSet {
            doRefresh()
        }
    }

    private var showingLog: Bool

    convenience init(director: DirectorInterface, model: Model, dismiss: @escaping () -> Void) {
        self.init(director: director, model: model,
                  object: nil, mode: .single(.create),
                  dismiss: { _ in dismiss() })
    }

    required init(director: DirectorInterface, model: Model, object: ModelResultsSet?, mode: PresenterMode, dismiss: @escaping PresenterDone<Goal>) {
        self.model = model
        self.director = director
        self.dismiss = dismiss
        self.data = DebugData(text: "")
        self.showingLog = true
        director.debugLogCache.notify = { logText in
            if self.showingLog {
                self.data.text = logText
            }
        }
    }

    var refresh: (DebugData) -> Void = { _ in } {
        didSet {
            doRefresh()
        }
    }

    func doRefresh() {
        Dispatch.toForeground {
            self.refresh(self.data)
        }
    }

    func close() {
        director.debugLogCache.notify = nil
    }

    /// Clear data
    func clear() {
        director.debugLogCache.log = ""
    }

    /// Show the log data
    func showLog() {
        showingLog = true
        data.text = director.debugLogCache.log
    }

    /// Show notifications status
    func showNotifications() {
        showingLog = false
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            guard requests.count > 0 else {
                self.data = DebugData(text: "No pending notifications")
                return
            }

            var str = ""
            requests.forEach { request in
                let name = request.content.body
                let badge: String
                if let badgeNum = request.content.badge,
                    let badgeInt = badgeNum as? Int {
                    badge = String(badgeInt)
                } else {
                    badge = "(no badge)"
                }
                let due: String
                if let trigger = request.trigger,
                    let calendarTrigger = trigger as? UNCalendarNotificationTrigger,
                    let date = calendarTrigger.nextTriggerDate() {
                    due = String(describing: date)
                } else {
                    due = "(can't decode)"
                }

                let cat = request.content.categoryIdentifier

                str += "NF name:'\(name)' badge:\(badge) due:\(due) cat:\(cat)\n\n"
            }
            self.data = DebugData(text: str)
        }
    }

    /// Custom command
    func doCommand(cmd: String) {
        
    }
}
