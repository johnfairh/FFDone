//
//  DebugPresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation
import UserNotifications

struct DebugData {
    let text: String
}

/// Presenter inputs, commands, outputs
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
}

class DebugPresenter: Presenter, DebugPresenterInterface {
    typealias ViewInterfaceType = DebugPresenterInterface

    private let model: Model
    private let director: DirectorInterface

    private var data: DebugData {
        didSet {
            doRefresh()
        }
    }

    convenience init(director: DirectorInterface, model: Model) {
        self.init(director: director, model: model, object: nil, mode: .single(.view), dismiss: { _ in })
    }

    required init(director: DirectorInterface, model: Model, object: ModelResultsSet?, mode: PresenterMode, dismiss: @escaping PresenterDone<Goal>) {
        self.model = model
        self.director = director
        self.data = DebugData(text: "Boo")
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

    /// Clear data
    func clear() {
        self.data = DebugData(text: "")
    }

    /// Show the log data
    func showLog() {

    }

    /// Show notifications status
    func showNotifications() {
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
                    let intervalTrigger = trigger as? UNTimeIntervalNotificationTrigger,
                    let date = intervalTrigger.nextTriggerDate() {
                    due = String(describing: date)
                } else {
                    due = "(can't decode)"
                }

                str += "NF name:'\(name)' badge:\(badge) due:\(due)\n\n"
            }
            self.data = DebugData(text: str)
        }
    }

    /// Custom command
    func doCommand(cmd: String) {
        
    }
}
