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
        customTagTextLabel?.layer.cornerRadius = 6
        customTagTextLabel?.layer.masksToBounds = true
        customTagTextLabel?.isUserInteractionEnabled = true

        // XXX start temp coloring
        customTextLabel?.textColor = .text
        customDetailTextLabel?.textColor = .text
        backgroundColor = nil // can't figure out how to set transparent in storyboard
        // XXX end temp coloring

        let tagGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapTagTextLabel(_:)))
        customTagTextLabel.addGestureRecognizer(tagGestureRecognizer)

        customImageView.enableRoundCorners()
    }

    @IBAction func didTapTagTextLabel(_ sender: UIGestureRecognizer) {
        GoalsTableViewController.shared?.doSearchForTag(tag: tagText)
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

    /// Slight hack to locate this VC from a cell...
    fileprivate static var shared: GoalsTableViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        // XXX start temp coloring
        view.backgroundColor = .background
        let selectedView = UIView()
        selectedView.backgroundColor = .tableHighlight
        UITableViewCell.appearance(whenContainedInInstancesOf: [GoalsTableViewController.self]).selectedBackgroundView = selectedView
        // XXX end temp coloring

        presenter.reload = { [weak self] queryResults in
            self?.reloadTable(queryResults: queryResults)
        }

        if presenter.isSearchable {
            enableSearch(scopes: ["Both", "Name", "Tag"],
                         textColor: .text)
        }

        navigationItem.leftBarButtonItem = nil

        if GoalsTableViewController.shared == nil {
            GoalsTableViewController.shared = self
        }

        presenter.registerInvocation() { [weak self] tag in
            self?.doSearchForTag(tag: tag)
        }
    }

    func willDisplaySectionHeader(_ header: UITableViewHeaderFooterView) {
        // XXX start temp coloring
        header.textLabel?.textColor = .text
        // XXX end temp coloring
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
        guard searchBar.textField.autoCompleteText(newText: text, suggestions: presenter.tags) else {
            return true
        }
        Dispatch.toForeground {
            self.updateSearchResults(for: self.navigationItem.searchController!)
        }
        return false
    }

    /// The actual search prompt
    public override func updateTableForSearch(text: String, scopeIndex: Int) {
        presenter.updateSearchResults(text: text, type: GoalsTableSearchType(rawValue: scopeIndex) ?? .both)
    }

    /// API up from `GoalTableCell` to implement the filter-by-tag usecase when a tag
    /// label gets clicked.
    public func doSearchForTag(tag: String) {
        guard let searchController = navigationItem.searchController else {
            Log.fatal("Lost the searchcontroller")
        }
        searchController.isActive = true
        searchController.searchBar.text = "=\(tag)"
        searchController.searchBar.selectedScopeButtonIndex = GoalsTableSearchType.tag.rawValue
        updateSearchResults()
    }
}
