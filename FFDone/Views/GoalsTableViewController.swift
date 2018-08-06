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
    var tagText: String = ""

    override func awakeFromNib() {
        super.awakeFromNib()
        customTagTextLabel?.backgroundColor = UIColor(named: "TagBackgroundColour")
        customTagTextLabel?.layer.cornerRadius = 6
        customTagTextLabel?.layer.masksToBounds = true
        customTagTextLabel?.isUserInteractionEnabled = true

        let tagGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapTagTextLabel(_:)))
        customTagTextLabel.addGestureRecognizer(tagGestureRecognizer)
    }

    @IBAction func didTapTagTextLabel(_ sender: UIGestureRecognizer) {
        GoalsTableViewController.shared?.doSearchForTag(tag: tagText)
    }

    func configure(_ modelObject: Goal) {
        customTextLabel?.text       = modelObject.name
        customDetailTextLabel?.text = modelObject.progressText + modelObject.debugText
        customImageView?.image      = modelObject.badgedImage
        if let tagText = modelObject.tag {
            customTagTextLabel?.isHidden = false
            customTagTextLabel?.text = " \(tagText) "
            self.tagText = tagText
        } else {
            customTagTextLabel?.isHidden = true
        }
    }
}

class GoalsTableViewController: PresentableTableVC<GoalsTablePresenter>,
    TableModelDelegate,
    UISearchResultsUpdating,
    UISearchBarDelegate
{
    fileprivate static var shared: GoalsTableViewController?

    private static let searchScopes = ["Both", "Name", "Tag"]

    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.reload = { [weak self] queryResults in
            self?.reloadTable(queryResults: queryResults)
        }

        if presenter.isSearchable {
            let searchController = UISearchController(searchResultsController: nil)
            searchController.obscuresBackgroundDuringPresentation = false
            searchController.searchBar.autocapitalizationType = .none
            searchController.searchBar.scopeButtonTitles = GoalsTableViewController.searchScopes
            searchController.searchBar.selectedScopeButtonIndex = -1
            searchController.searchBar.showsScopeBar = true
            searchController.searchBar.delegate = self
            searchController.searchResultsUpdater = self
            navigationItem.searchController = searchController
            definesPresentationContext = true
        }

        navigationItem.leftBarButtonItem = nil

        if GoalsTableViewController.shared == nil {
            GoalsTableViewController.shared = self
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

    // MARK: - Select

    func selectObject(_ modelObject: ModelObject) {
        presenter.selectGoal(modelObject as! Goal)
    }

    func leadingSwipeActionsForObject(_ goal: Goal) -> UISwipeActionsConfiguration? {
        guard !goal.isComplete else {
            return nil
        }
        // TODO: these things should move to `Goal`
        let title = (goal.stepsToGo == 1) ? "Complete" : "Progress"
        let action = UIContextualAction(style: .normal, title: title) { _, _, continuation in
            goal.currentSteps = goal.currentSteps + 1
            continuation(true)
        }
        action.backgroundColor = UIColor(named: "StepSwipeColour") ?? .green
        return UISwipeActionsConfiguration(actions: [action])
    }

    // MARK: - Search

    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if searchBar.selectedScopeButtonIndex == -1 {
            searchBar.selectedScopeButtonIndex = 0
        }
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.selectedScopeButtonIndex = -1
    }

    public func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        Dispatch.toForeground {
            self.updateSearchResults(for: self.navigationItem.searchController!)
        }
    }

    public func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let text = searchBar.text ?? ""
        func scopeToSearchType(scope: Int) -> GoalsTableSearchType {
            switch scope {
            case 0: return .either
            case 1: return .name
            case 2: return .tag
            default: return .either
            }
        }
        presenter.updateSearchResults(text: text,
                                      type: scopeToSearchType(scope: searchBar.selectedScopeButtonIndex))
    }

    public func doSearchForTag(tag: String) {
        Log.log("Searching for tag \(tag)")
        guard let searchController = navigationItem.searchController else {
            Log.fatal("Lost the searchcontroller")
        }
        searchController.isActive = true
        searchController.searchBar.text = "=\(tag)"
        searchController.searchBar.selectedScopeButtonIndex = 2
        updateSearchResults(for: searchController)
    }
}
