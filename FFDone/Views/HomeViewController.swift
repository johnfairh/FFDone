//
//  HomeViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation
import PieCharts

/// VC for the home screen
class HomeViewController: PresentableVC<HomePresenterInterface> {
    @IBOutlet weak var pieChartView: PieChart!
    @IBOutlet weak var progressLabel: UILabel!

    public override func viewDidLoad() {
        presenter.refresh = { [unowned self] current, total in
            self.relayout(current: current, total: total)
        }
        // 1-time pie configuration
        pieChartView.referenceAngle = CGFloat(270)
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
}
