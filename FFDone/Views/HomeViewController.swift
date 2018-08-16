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
    @IBOutlet weak var tagCloudView: UIView!
    @IBOutlet weak var alertsTableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var alertsTableView: UIView!

    var origTagHeight: CGFloat = 0.0
    public override func viewDidLoad() {
        // start with just pie visible
        alertsTableHeightConstraint.constant = 0 /// this is just a constant
        origTagHeight = tagCloudViewHeightConstraint.constant
        tagCloudViewHeightConstraint.constant = 0


        presenter.refresh = { [unowned self] current, total in
            self.relayout(current: current, total: total)
        }
        // 1-time pie configuration
        pieChartView.referenceAngle = CGFloat(270)
        pieChartView.delegate = self
        pieChartView.layer.borderWidth  = 1
        pieChartView.layer.borderColor  = UIColor.lightGray.cgColor
    }

    var firstRun: Bool = false
    var pieCH: CGFloat = 0.0

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !firstRun {
            firstRun = true
            let safeAreaHeight = view.safeAreaLayoutGuide.layoutFrame.height
            let pieHeight = pieChartView.frame.height

            pieCH = (safeAreaHeight - pieHeight) / 2
            pieChartViewTopConstraint.constant = pieCH
        }
    }

    private func relayout(current: Int, total: Int) {
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

        pieChartView.clear()
        let oldAnimDuration = pieChartView.animDuration
        pieChartView.animDuration = 0
        pieChartView.models = [
            PieSliceModel(value: stepsDone, color: .green),
            PieSliceModel(value: stepsToDo, color: .red)
        ]
        pieChartView.slices.forEach { $0.view.selectedOffset = CGFloat(5.0) }
        pieChartView.animDuration = oldAnimDuration
    }

    func onSelected(slice: PieSlice, selected: Bool) {
        UIView.animate(withDuration: 0.2) {
            if selected {
                self.pieChartViewTopConstraint.constant = 0
                self.tagCloudViewHeightConstraint.constant = self.origTagHeight
            } else {
                self.pieChartViewTopConstraint.constant = self.pieCH
                self.tagCloudViewHeightConstraint.constant = 0
            }
            self.view.layoutIfNeeded()
        }
    }
}
