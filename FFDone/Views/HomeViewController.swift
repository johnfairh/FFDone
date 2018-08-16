//
//  HomeViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation
import PieCharts
import DBSphereTagCloud_Framework

/// VC for the home screen
class HomeViewController: PresentableVC<HomePresenterInterface>, PieChartDelegate {
    @IBOutlet weak var pieChartViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var pieChartView: PieChart!
    @IBOutlet weak var progressLabel: UILabel!

    @IBOutlet weak var tagCloudViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var tagCloudViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tagCloudView: DBSphereView!

    @IBOutlet weak var alertsTableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var alertsTableView: UIView!

    public override func viewDidLoad() {
        presenter.refresh = { [unowned self] current, total in
            self.recalculateSlices(current: current, total: total)
        }
        // 1-time pie view configuration
        pieChartView.referenceAngle = CGFloat(270)
        pieChartView.delegate = self
        pieChartView.layer.borderWidth  = 1
        pieChartView.layer.borderColor  = UIColor.lightGray.cgColor
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
        UIView.animate(withDuration: 0.2) {
            if !selected {
                self.positionChartOnlyView()
            } else {
                if !self.isTagCloudVisible {
                    self.positionChartAndTagsView()
                }
                self.updateTagCloud(complete: slice.data.id == HomeViewController.kCompleteSliceId)
            }
            self.view.layoutIfNeeded()
        }
    }

    func updateTagCloud(complete: Bool) {
        Log.log("Tag cloud now shows \(complete ? "complete" : "incomplete") tags")
        var buttons: [UIButton] = []

        for i in 1..<50 {
            let btn = UIButton(type: .system)
            btn.setTitle("\(i)", for: .normal)
            btn.setTitleColor(.darkGray, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: UIFont.Weight.light)
            btn.frame = CGRect(x: 0, y: 0, width: 60, height: 20)
            buttons.append(btn)
            tagCloudView.addSubview(btn)
        }
        tagCloudView.setCloudTags(buttons)
    }
}
