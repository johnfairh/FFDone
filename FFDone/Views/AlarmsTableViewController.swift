//
//  AlarmsTableViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

class AlarmCell: UITableViewCell, TableCell {

    func configure(_ alarm: Alarm) {
        textLabel?.text       = alarm.name
        detailTextLabel?.text = "..."
        imageView?.image      = alarm.mainTableImage
    }
}

class AlarmsTableViewController: PresentableTableVC<AlarmsTablePresenter>,
TableModelDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.reload = { [weak self] queryResults in
            self?.reloadTable(queryResults: queryResults)
        }

        navigationItem.leftBarButtonItem = nil
    }

    private var tableModel: TableModel<AlarmCell, AlarmsTableViewController>!

    private func reloadTable(queryResults: ModelResults) {
        tableModel = TableModel(tableView: tableView,
                                fetchedResultsController: queryResults,
                                delegate: self)
        tableModel.start()
    }

    // MARK: - Section config
    func getSectionTitle(name: String) -> String {
        return Alarm.Section.titleMap[name]!
    }

    func getSectionObject(name: String) -> Alarm.Section {
        return Alarm.Section(rawValue: name)!
    }

    // MARK: - Delete

    func canDeleteObject(_ modelObject: Alarm) -> Bool {
        return presenter.canDeleteAlarm(modelObject)
    }

    func deleteObject(_ modelObject: Alarm) {
        presenter.deleteAlarm(modelObject)
    }

    // MARK: - Row actions

    func selectObject(_ modelObject: ModelObject) {
        presenter.selectAlarm(modelObject as! Alarm)
    }

    func leadingSwipeActionsForObject(_ alarm: Alarm) -> TableSwipeAction? {
        return presenter.swipeActionForAlarm(alarm)
    }
}
