//
//  AlarmsTablePresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Interface from the Alarms Table VC to presenter -- requirements unique to alarms table.
@MainActor
protocol AlarmsTablePresenterInterface: TablePresenterInterface {
    func canMoveAlarm(_ alarm: Alarm) -> Bool
    func canMoveAlarmTo(_ alarm: Alarm, toSection: Alarm.Section, toRowInSection: Int) -> Bool
    func moveAlarm(_ alarm: Alarm, fromRowInSection: Int, toSection: Alarm.Section, toRowInSection: Int, tableView: UITableView)

    func canDeleteAlarm(_ alarm: Alarm) -> Bool
    func deleteAlarm(_ alarm: Alarm)

    func selectAlarm(_ alarm: Alarm)

    func swipeActionForAlarm(_ alarm: Alarm) -> TableSwipeAction?

    func toggleSubscription() async
    var refresh: (Bool) -> Void { get set }
}

// MARK: - Presenter

class AlarmsTablePresenter: TablePresenter<DirectorInterface>, Presenter, AlarmsTablePresenterInterface {
    typealias ViewInterfaceType = AlarmsTablePresenter//Interface --- XXX weird swift generics vs. protocols runtime crash workaround XXX

    private let selectedCallback: PresenterDone<Alarm>

    private var listenTask: Task<Void,Never>?
    private var listener: NotificationListener?

    var refresh: (Bool) -> Void = { _ in } {
        didSet {
            refreshUI()
        }
    }

    required init(director: DirectorInterface, model: Model, object: ModelResultsSet?, mode: PresenterMode, dismiss: @escaping PresenterDone<Alarm>) {
        self.selectedCallback = dismiss
        super.init(director: director, model: model, object: object, mode: mode)

        let didSaveNotifications = model.notifications(name: .NSManagedObjectContextDidSave)
        listenTask = Task.detached { [weak self] in
            for await _ in didSaveNotifications {
                await self?.refreshAlarmCount()
            }
        }
        refreshAlarmCount()
        refreshUI()
    }

    deinit {
        listenTask?.cancel()
        listenTask = nil
    }

    func refreshUI() {
        refresh(Prefs.subbed)
    }

    func refreshAlarmCount() {
        let count = Alarm.getActiveAlarmCount(model: model)
        director.request(.setActiveAlarmCount(count))
    }

    // MARK: - Move

    // Allow reorder of active alarms - inactive sorted by due date

    func canMoveAlarm(_ alarm: Alarm) -> Bool {
        return alarm.isActive
    }

    func canMoveAlarmTo(_ alarm: Alarm, toSection: Alarm.Section, toRowInSection: Int) -> Bool {
        return toSection == .active
    }

    func moveAlarm(_ alarm: Alarm, fromRowInSection: Int, toSection: Alarm.Section, toRowInSection: Int, tableView: UITableView) {
        moveAndRenumber(fromRow: fromRowInSection, toRow: toRowInSection, sortOrder: Alarm.primarySortOrder)
        model.saveAndWait()
    }

    // MARK: - Delete

    func canDeleteAlarm(_ alarm: Alarm) -> Bool {
        return isEditable
    }

    func deleteAlarm(_ alarm: Alarm) {
        if !alarm.isActive {
            if let uid = alarm.notificationUid {
                director.request(.cancelAlarm(uid))
            }
        }
        alarm.delete(from: model)
        model.save()
    }

    func selectAlarm(_ alarm: Alarm) {
        selectedCallback(alarm)
    }

    func createNewObject() {
        director.request(.createAlarm(model))
    }

    // MARK: - Swipe

    func swipeActionForAlarm(_ alarm: Alarm) -> TableSwipeAction? {
        guard alarm.isActive else {
            return nil
        }

        return TableSwipeAction(text: "Done", color: .tableLeadingSwipe, action: {
            Task {
                if case .oneShot = alarm.kind {
                    alarm.delete(from: self.model)
                    self.model.save()
                } else {
                    alarm.debugDeactivate()
                    await self.director.request(.scheduleAlarm(alarm))
                    self.model.save()
                }
            }
        })
    }

    // MARK: Subscription

    func toggleSubscription() {
        Task {
            await director.request(.toggleSubscription)
            refreshAlarmCount()
            refreshUI()
        }
    }
}
