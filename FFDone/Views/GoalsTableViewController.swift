//
//  GoalsTableViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

class GoalCell: UITableViewCell, TableCell {

    @IBOutlet weak var customImageView: UIImageView!
    @IBOutlet weak var customTextLabel: UILabel!
    @IBOutlet weak var customDetailTextLabel: UILabel!
    @IBOutlet weak var customTagTextLabel: UILabel!
    private var tagText = ""

    override func awakeFromNib() {
        super.awakeFromNib()
        customTagTextLabel?.backgroundColor = .tagBubble
        customTagTextLabel?.layer.cornerCurve = .continuous
        customTagTextLabel?.layer.cornerRadius = 6
        customTagTextLabel?.layer.masksToBounds = true
        customTagTextLabel?.isUserInteractionEnabled = true

        let tagGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapTagTextLabel(_:)))
        customTagTextLabel.addGestureRecognizer(tagGestureRecognizer)

        customImageView.enableRoundCorners()
    }

    @IBAction func didTapTagTextLabel(_ sender: UIGestureRecognizer) {
        var responder: UIResponder? = self
        while responder != nil {
            if let table = responder as? GoalsTableViewController {
                table.doSearchForTag(tag: tagText)
                return
            }
            responder = responder!.next
        }
    }

    func configure(_ goal: Goal) {
        customTextLabel?.text       = goal.name
        customDetailTextLabel?.text = goal.shortProgressText + (App.debugMode ? goal.debugText : "")
        customImageView?.image      = goal.badgedImage
        if let tagText = goal.tag {
            customTagTextLabel?.isHidden = false
            customTagTextLabel?.text = " \(tagText) "
            self.tagText = tagText
        } else {
            customTagTextLabel?.isHidden = true
        }
    }
}

class GoalsTableViewController: PresentableTableVC<GoalsTablePresenter>,
    TableModelDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        presenter.reload = { [weak self] queryResults in
            self?.reloadTable(queryResults: queryResults)
        }

        if presenter.isSearchable {
            enableSearch(scopes: ["Both", "Name", "Tag"])
        }
        enablePullToCreate()
        navigationItem.leftBarButtonItem = nil

        presenter.invokeSearch = { [weak self] data in
            self?.doInvocationSearch(data: data)
        }
    }

    private var tableModel: TableModel<GoalCell, GoalsTableViewController>!

    private func reloadTable(queryResults: ModelResults) {
        tableModel = TableModel(tableView: tableView,
                                fetchedResultsController: queryResults,
                                delegate: self)
        tableModel.start()
    }

    // MARK: - Section config
    func getSectionTitle(name: String) -> String {
        return Goal.Section.titleMap[name]!
    }

    func getSectionObject(name: String) -> Goal.Section {
        return Goal.Section(rawValue: name)!
    }

    // MARK: - Delete

    func canDeleteObject(_ modelObject: Goal) -> Bool {
        return presenter.canDeleteGoal(modelObject)
    }

    func deleteObject(_ modelObject: Goal) {
        presenter.deleteGoal(modelObject)
    }

    // MARK: - Move

    func canMoveObject(_ modelObject: Goal) -> Bool {
        return presenter.canMoveGoal(modelObject)
    }

    func canMoveObjectTo(_ goal: Goal, toSection: Goal.Section, toRowInSection: Int) -> Bool {
        return presenter.canMoveGoalTo(goal, toSection: toSection, toRowInSection: toRowInSection)
    }

    func moveObject(_ goal: Goal,
                    fromRowInSection: Int,
                    toSection: Goal.Section, toRowInSection: Int) {
        presenter.moveGoal(goal,
                           fromRowInSection: fromRowInSection,
                           toSection: toSection, toRowInSection: toRowInSection,
                           tableView: tableView)
    }

    // MARK: - Row actions

    func selectObject(_ modelObject: ModelObject) {
        presenter.selectGoal(modelObject as! Goal)
    }

    func leadingSwipeActionsForObject(_ goal: Goal) -> TableSwipeAction? {
        return presenter.swipeActionForGoal(goal)
    }

    // MARK: - Search

    /// Autocomplete against the tag list if we are searching tags
    public override func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard searchBar.selectedScopeButtonIndex == GoalsTableSearchType.tag.rawValue else {
            return true
        }
        guard searchBar.searchTextField.autoCompleteText(newText: text, suggestions: presenter.tags) else {
            return true
        }
        Dispatch.toForeground {
            self.refreshSearch()
        }
        return false
    }

    /// The actual search prompt
    public override func updateTableForSearch(tokens: [UISearchToken], text: String, scopeIndex: Int) {
        let epoch = tokens.first.flatMap { $0.representedEpoch }
        presenter.updateSearchResults(epoch: epoch, text: text, type: GoalsTableSearchType(rawValue: scopeIndex) ?? .both)
    }

    /// API up from `GoalTableCell` to implement the filter-by-tag usecase when a tag
    /// label gets clicked.
    func doSearchForTag(tag: String) {
        invokeSearch(text: Goal.queryStringForExactTag(tag), scopeIndex: GoalsTableSearchType.tag.rawValue)
    }

    func doInvocationSearch(data: GoalsTableInvocationData) {
        let token = UISearchToken(epoch: data.epoch)
        invokeSearch(tokens: [token], text: Goal.queryStringForExactTag(data.tag), scopeIndex: GoalsTableSearchType.tag.rawValue)
    }
}

/// Helpers for our epoch search tokens.
extension UISearchToken {
    convenience init(epoch: Epoch) {
        self.init(icon: UIImage(systemName: "calendar.circle"), text: epoch.shortName)
        representedObject = epoch
    }

    var representedEpoch: Epoch {
        representedObject as! Epoch
    }
}
