//
//  AlarmsTableViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

class AlarmCell: UITableViewCell, TableCell {

    override func awakeFromNib() {
        super.awakeFromNib()

        // XXX start temp coloring -- can move to UIAppearance, hoorah!
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .tableHighlight
        // XXX start temp coloring
    }

    func configure(_ alarm: Alarm) {

        // XXX start temp coloring
        textLabel?.textColor = .text
        detailTextLabel?.textColor = .text
        backgroundColor = nil // can't figure out how to set transparent in storyboard
        // XXX end temp coloring

        textLabel?.text = alarm.name
        detailTextLabel?.text = alarm.caption
        imageView?.image = alarm.mainTableImage
    }
}

class AlarmsTableViewController: PresentableTableVC<AlarmsTablePresenter>,
TableModelDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // XXX start temp coloring
        view.backgroundColor = .background
        tableView.separatorColor = .tableSeparator
        // XXX end temp coloring

        presenter.reload = { [weak self] queryResults in
            self?.reloadTable(queryResults: queryResults)
        }

        navigationItem.leftBarButtonItem = nil
    }

    func willDisplaySectionHeader(_ header: UITableViewHeaderFooterView) {
        // XXX start temp coloring
        header.textLabel?.textColor = .text
        // XXX end temp coloring
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

    // MARK: - Move

    func canMoveObject(_ modelObject: Alarm) -> Bool {
        return presenter.canMoveAlarm(modelObject)
    }

    func canMoveObjectTo(_ alarm: Alarm, toSection: Alarm.Section, toRowInSection: Int) -> Bool {
        return presenter.canMoveAlarmTo(alarm, toSection: toSection, toRowInSection: toRowInSection)
    }

    func moveObject(_ alarm: Alarm,
                    fromRowInSection: Int,
                    toSection: Alarm.Section, toRowInSection: Int) {
        presenter.moveAlarm(alarm,
                            fromRowInSection: fromRowInSection,
                            toSection: toSection, toRowInSection: toRowInSection,
                            tableView: tableView)
    }

    // MARK: - Row actions

    func selectObject(_ modelObject: ModelObject) {
        presenter.selectAlarm(modelObject as! Alarm)
    }

    func leadingSwipeActionsForObject(_ alarm: Alarm) -> TableSwipeAction? {
        return presenter.swipeActionForAlarm(alarm)
    }
}
