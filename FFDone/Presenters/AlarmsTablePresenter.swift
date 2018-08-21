//
//  AlarmsTablePresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Interface from the Alarms Table VC to presenter -- requirements unique to alarms table.
protocol AlarmsTablePresenterInterface: TablePresenterInterface {
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

    func canDeleteAlarm(_ alarm: Alarm) -> Bool {
        return isEditable
    }

    func deleteAlarm(_ alarm: Alarm) {
        // XXX deschedule
        alarm.delete(from: model)
        model.save()
    }

    func selectAlarm(_ alarm: Alarm) {
        selectedCallback(alarm)
    }

    func createNewObject() {
//        director.request(.createGoal(model))
    }

    // MARK: - Swipe

    func swipeActionForAlarm(_ alarm: Alarm) -> TableSwipeAction? {
        guard alarm.isActive else {
            return nil
        }

        return TableSwipeAction(text: "Done", colorName: "StepSwipeColour", action: {
            if case .oneShot = alarm.kind {
                alarm.delete(from: self.model)
            } else {
                alarm.deactivate()
            }
            self.model.save()
        })
    }
}
