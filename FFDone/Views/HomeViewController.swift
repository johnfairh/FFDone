//
//  HomeViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation
import PieCharts

/// VC for the home screen
class HomeViewController: PresentableVC<HomePresenterInterface>, PieChartDelegate {
    @IBOutlet weak var pieChartViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var pieChartView: PieChart!
    @IBOutlet weak var progressLabel: UILabel!

    @IBOutlet weak var tagCloudViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var tagCloudViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tagCloudView: TagCloudView!

    @IBOutlet weak var alertsTableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var alertsTableView: UIView!

    public override func viewDidLoad() {
        presenter.refreshSteps = { [unowned self] current, total in
            self.recalculateSlices(current: current, total: total)
        }
        // 1-time pie view configuration
        pieChartView.referenceAngle = CGFloat(270)
        pieChartView.delegate = self

        pieChartView.layer.borderWidth  = 1
        pieChartView.layer.borderColor  = UIColor.lightGray.cgColor
        pieChartView.backgroundColor    = UIColor.init(white: 0.0, alpha: 0.0)

        tagCloudView.layer.borderWidth  = 1
        tagCloudView.layer.borderColor  = UIColor.lightGray.cgColor
    }

    var safeAreaSize: CGSize?

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if safeAreaSize == nil {
            safeAreaSize = view.safeAreaLayoutGuide.layoutFrame.size

            // Initial layout pass
            alertsTableHeightConstraint.constant = 80 // from subvc
            positionChartOnlyView()
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tagCloudView.timerStart()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        tagCloudView.timerStop()
    }

    func positionChartOnlyView() {
        guard let safeAreaSize = safeAreaSize else { return }

        tagCloudViewHeightConstraint.constant = 0
        pieChartViewTopConstraint.constant =
            (safeAreaSize.height -
             alertsTableHeightConstraint.constant -
             pieChartView.frame.height) / 2
    }

    var isTagCloudVisible: Bool {
        return tagCloudViewHeightConstraint.constant > 0
    }

    func positionChartAndTagsView() {
        guard let safeAreaSize = safeAreaSize else { return }

        var spaceAboveAlerts = safeAreaSize.height - alertsTableHeightConstraint.constant
        if alertsTableHeightConstraint.constant > 0 {
            spaceAboveAlerts -= 4 // margin
        }

        let maxTagCloudSide = spaceAboveAlerts - pieChartView.frame.height
        let tagCloudSide = min(maxTagCloudSide, safeAreaSize.width)
           /// Need to chuck a decent margin on either side for tag overflow - about what we
           /// have in this 80pt alerts demo, reduce sAS.width.

        /// Need extra margin of maybe 10pt vertically to deal with tag height overlap.
        pieChartViewTopConstraint.constant =
            (spaceAboveAlerts - tagCloudSide - pieChartView.frame.height) / 2
        tagCloudViewHeightConstraint.constant = tagCloudSide
        tagCloudViewTopConstraint.constant =
            pieChartViewTopConstraint.constant + pieChartView.frame.height
    }

    private static let kIncompleteSliceId = 0
    private static let kCompleteSliceId = 1
    private static let kSliceCount = 2

    private func recalculateSlices(current: Int, total: Int) {
        let stepsToDo: Double
        let stepsDone: Double

        if total == 0 {
            stepsToDo = 0
            stepsDone = 1
        } else {
            stepsDone = Double(current)
            stepsToDo = Double(total - current)
        }

        let donePercent = Int((stepsDone * 100) / (stepsDone + stepsToDo))
        progressLabel.text = "\(donePercent)%"

        // Try to suppress weirdness during pie population... not 100% successful :/
        pieChartView.clear()
        let oldAnimDuration = pieChartView.animDuration
        pieChartView.animDuration = 0
        defer { pieChartView.animDuration = oldAnimDuration }

        // Add slices
        pieChartView.models =
            [PieSliceModel(value: stepsDone, color: .green), // kIncompleteSliceId
             PieSliceModel(value: stepsToDo, color: .red)]   // kCompleteSliceId

        // Configure how far out the slice pops when clicked
        pieChartView.slices.forEach { $0.view.selectedOffset = CGFloat(2.0) }
    }

    // If a slice is selected and the user clicks the other slice, we have
    // to programatically deselect the former slice.  This is slightly hacky
    // because we still get the 'onSelected' callback made reentrantly, and
    // have to ignore it....
    var ignoreNextOnSelected = false

    func onSelected(slice: PieSlice, selected: Bool) {
        guard !ignoreNextOnSelected else {
            ignoreNextOnSelected = false
            return
        }

        if selected && isTagCloudVisible {
            ignoreNextOnSelected = true
            Dispatch.toForeground {
                self.pieChartView.slices[1 - slice.data.id].view.selected = false
            }
        }
        UIView.animate(withDuration: 0.2, animations: {
            if !selected {
                self.tagCloudView.clearCloudTags()
                self.positionChartOnlyView()
            } else {
                if !self.isTagCloudVisible {
                    self.positionChartAndTagsView()
                }
            }
            self.view.layoutIfNeeded()
        }, completion: { _ in
            if selected {
                self.updateTagCloud(complete: slice.data.id == HomeViewController.kCompleteSliceId)
            }
        })
    }

    func updateTagCloud(complete: Bool) {
        let tags = [ "levelling", "crafting", "gathering", "arr", "zone", "heavensward", "legacy", "(untagged)"]

        let buttons = tags.map { tag -> UIButton in
            let button = UIButton(type: .system).configureForTagCloud(tag: tag)
            button.addTarget(self, action: #selector(tagCloudButtonTapped), for: .touchUpInside)
            return button
        }
        tagCloudView.setCloudTags(buttons)
    }

    @objc func tagCloudButtonTapped(_ sender: UIButton) {
        guard let tag = sender.titleLabel?.text else {
            return
        }
        Log.log("GO TO TAG \(tag)")
    }
}

extension UIButton {

    func configureForTagCloud(tag: String) -> UIButton {
        Log.assert(buttonType == .system)
        setTitle(tag, for: .normal)
        setTitleColor(.darkText, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 24, weight: .light)
        backgroundColor = UIColor(named: "TagBackgroundColour")
        sizeToFit()
        frame.size.width += 8
        layer.cornerRadius = 6
        layer.masksToBounds = true
        return self
    }
}
