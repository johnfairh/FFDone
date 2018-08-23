//
//  AlarmsTablePresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Interface from the Alarms Table VC to presenter -- requirements unique to alarms table.
protocol AlarmsTablePresenterInterface: TablePresenterInterface {

    func canMoveAlarm(_ alarm: Alarm) -> Bool
    func canMoveAlarmTo(_ alarm: Alarm, toSection: Alarm.Section, toRowInSection: Int) -> Bool
    func moveAlarm(_ alarm: Alarm, fromRowInSection: Int, toSection: Alarm.Section, toRowInSection: Int, tableView: UITableView)

    func canDeleteAlarm(_ alarm: Alarm) -> Bool
    func deleteAlarm(_ alarm: Alarm)

    func selectAlarm(_ alarm: Alarm)

    func swipeActionForAlarm(_ alarm: Alarm) -> TableSwipeAction?
}

// MARK: - Presenter

class AlarmsTablePresenter: TablePresenter<DirectorInterface>, Presenter, AlarmsTablePresenterInterface {
    typealias ViewInterfaceType = AlarmsTablePresenter//Interface --- XXX weird swift generics vs. protocols runtime crash workaround XXX

    private let selectedCallback: PresenterDone<Alarm>

    required init(director: DirectorInterface, model: Model, object: ModelResultsSet?, mode: PresenterMode, dismiss: @escaping PresenterDone<Alarm>) {
        self.selectedCallback = dismiss
        super.init(director: director, model: model, object: object, mode: mode)
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
//        director.request(.createAlarm(model))
    }

    // MARK: - Swipe

    func swipeActionForAlarm(_ alarm: Alarm) -> TableSwipeAction? {
        guard alarm.isActive else {
            return nil
        }

        return TableSwipeAction(text: "Done", colorName: "StepSwipeColour", action: {
            if case .oneShot = alarm.kind {
                alarm.delete(from: self.model)
                self.model.save()
            } else {
                alarm.debugDeactivate()
                self.director.request(.scheduleAlarm(alarm, { uid in
                    if let uid = uid {
                        alarm.notificationUid = uid
                    }
                    self.model.save()
                }))
            }
        })
    }
}
