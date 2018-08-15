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
        let donePercent = (total == 0) ? 0 : ((current * 100) / total)
        progressLabel.text = "\(donePercent)%"

        pieChartView.clear()
        pieChartView.models = [
            PieSliceModel(value: Double(current), color: .green),
            PieSliceModel(value: Double(total - current), color: .red)
        ]
        pieChartView.slices.forEach { $0.view.selectedOffset = CGFloat(5.0) }
    }
}
