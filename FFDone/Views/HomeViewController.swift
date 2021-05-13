//
//  HomeViewController.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation
import PieCharts

// Home Screen View Controller stack

/// Pager - provide one home screen page (pie + cloud) per Epoch
class HomePagerViewController: PresentablePagerVC<HomePagerPresenter> {
    public override func viewDidLoad() {
        pageViewControllerName = "HomeViewController"
        super.viewDidLoad()
    }
}

/// Page - the home screen itself, can be multiple instances embedded in the
/// `HomePagerViewController`.
class HomeViewController: PresentableVC<HomePresenterInterface>, PieChartDelegate {
    @IBOutlet weak var pieChartViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var pieChartView: PieChart!
    @IBOutlet weak var progressLabel: UILabel!

    @IBOutlet weak var tagCloudViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var tagCloudViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tagCloudView: TagCloudView!
    @IBOutlet weak var headingImageView: UIImageView!
    
    @IBOutlet weak var headingImageViewHeightConstraint: NSLayoutConstraint!
    public override func viewDidLoad() {
        super.viewDidLoad()

        presenter.refresh = { [unowned self] data in
            self.refreshData(data)
        }

        // 1-time pie view configuration
        pieChartView.referenceAngle = CGFloat(270)
        pieChartView.delegate = self
        pieChartView.backgroundColor = .systemBackground
    }

    var safeAreaSize: CGSize?

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if safeAreaSize == nil {
            safeAreaSize = view.safeAreaLayoutGuide.layoutFrame.size

            // Initial layout pass
            layoutChartOnlyView()
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

    @IBAction func didTapNewGoal(_ sender: UIButton) {
        presenter.createGoal()
    }

    @IBAction func didTapHeadingImage(_ sender: UITapGestureRecognizer) {
        guard sender.view != nil && sender.state == .ended else {
            return
        }
        presenter.showEpochs()
    }
    
    @IBAction func didTapNewAlarm(_ sender: UIButton) {
        presenter.createAlarm()
    }
    
    func layoutChartOnlyView() {
        guard let safeAreaSize = safeAreaSize else { return }

        tagCloudViewHeightConstraint.constant = 0

        let headingImageHeight = CGFloat(Tweaks.shared.epochImageHeight)
        headingImageViewHeightConstraint.constant = headingImageHeight

        let topOfSpaceForPie = headingImageView.frame.origin.y + headingImageHeight
        let extraBottomPad = CGFloat(40)
        let allSpaceForPie = safeAreaSize.height - topOfSpaceForPie - extraBottomPad
        let spaceSurroundingPie = allSpaceForPie - pieChartView.frame.height

        pieChartViewTopConstraint.constant =
            topOfSpaceForPie + (spaceSurroundingPie / 2)
    }

    var isTagCloudVisible: Bool {
        return tagCloudViewHeightConstraint.constant > 0
    }

    func layoutChartAndTagsView() {
        guard let safeAreaSize = safeAreaSize else { return }

        let spaceAboveAlerts = safeAreaSize.height

        let tagCloudVMargin = CGFloat(10) // deal with tag labels overflowing the frame
        let tagCloudHMargin = CGFloat(30) // same, but bigger because text...

        let maxTagCloudHeight = spaceAboveAlerts - pieChartView.frame.height - 2 * tagCloudVMargin
        let maxTagCloudWidth = safeAreaSize.width - (2 * tagCloudHMargin)
        let tagCloudSide = min(maxTagCloudHeight, maxTagCloudWidth)

        pieChartViewTopConstraint.constant =
            (spaceAboveAlerts - tagCloudSide - 2 * tagCloudVMargin - pieChartView.frame.height) / 2
        tagCloudViewHeightConstraint.constant = tagCloudSide
        tagCloudViewTopConstraint.constant =
            pieChartViewTopConstraint.constant + pieChartView.frame.height + tagCloudVMargin

        // This makes it actually animate instead of blinking out
        headingImageViewHeightConstraint.constant = 1
    }

    func finishLayoutChartAndTagsView() {
        headingImageViewHeightConstraint.constant = 0
    }

    var homeData: HomeData?
    var selectedSide: HomeSideType?

    private func refreshData(_ homeData: HomeData) {
        self.homeData = homeData

        // Image shenanigans.
        // Do the aspect-fit scaling manually so we can composite in the patch number text
        // *after* the scaling.
        if let originalImage = presenter.headingImage {
            let xScale = headingImageView.bounds.width / originalImage.size.width
            let yScale = CGFloat(Tweaks.shared.epochImageHeight) / originalImage.size.height
            let scale  = min(xScale, yScale)
            let size  = CGSize(width: originalImage.size.width * scale,
                               height: originalImage.size.height * scale)

            UIImage.badgeColor = .secondaryLabel
            UIImage.badgeFont = UIFont(name: "Copperplate", size: 18)!
            defer {
                UIImage.badgeColor = nil
                UIImage.badgeFont = nil
            }

            headingImageView.image = originalImage.imageWithSize(size, andBadge: presenter.headingOverlayText)
        }

        recalculateSlices(toDo: homeData.dataForSide(.incomplete).steps,
                          done: homeData.dataForSide(.complete).steps)
        updateTagCloud()
    }

    @IBAction func didSwipeDownPie(_ sender: UISwipeGestureRecognizer) {
        if let selectedSide = selectedSide {
            pieChartView.slices[selectedSide.rawValue].view.selected = false
        }
    }

    private func recalculateSlices(toDo: Int, done: Int) {
        let stepsToDo: Int
        let stepsDone: Int

        if toDo + done == 0 {
            stepsToDo = 0
            stepsDone = 1
        } else {
            stepsToDo = toDo
            stepsDone = done
        }

        var donePercent: Int
        if stepsToDo > 0 {
            donePercent = (stepsDone * 100) / (stepsDone + stepsToDo)
            if donePercent == 0 && done != 0 {
                donePercent = 1
            }
            progressLabel.text = "\(donePercent)%"
        } else {
            donePercent = 100
            progressLabel.text = ""
        }

        pieChartView.clear()
        let oldAnimDuration = pieChartView.animDuration
        pieChartView.animDuration = 0
        defer { pieChartView.animDuration = oldAnimDuration }

        // Adjust values to avoid giving tiny touch-targets
        switch donePercent {
        case 1..<10: donePercent = 10
        case 90..<100: donePercent = 90
        default: break
        }

        // Add slices
        pieChartView.models =
            [PieSliceModel(value: Double(donePercent), color: .pieComplete),  // TagType.complete.rawValue
             PieSliceModel(value: Double(100 - donePercent), color: .pieIncomplete)]// TagType.incomplete.rawValue

        // Configure how far out the slice pops when clicked
        pieChartView.slices.forEach { $0.view.selectedOffset = CGFloat(5.0) }

        // Are we supposed to have selected a slice?
        if let side = selectedSide {
            ignoreNextOnSelected = true
            pieChartView.slices[side.rawValue].view.selected = true
        }
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

        guard let sliceSide = HomeSideType(rawValue: slice.data.id) else {
            Log.fatal("Bad ID on slice: \(slice)")
        }

        if selected && isTagCloudVisible {
            ignoreNextOnSelected = true
            Dispatch.toForeground {
                self.pieChartView.slices[sliceSide.other.rawValue].view.selected = false
            }
        }
        if selected {
            animateOpen(side: sliceSide)
        } else {
            animateClosed()
        }
    }

    func animateClosed() {
        UIView.animate(withDuration: 0.3, animations: {
            self.selectedSide = nil
            self.tagCloudView.clearCloudTags()
            self.layoutChartOnlyView()
            self.view.layoutIfNeeded()
        })
    }

    func animateOpen(side: HomeSideType) {
        UIView.animate(withDuration: 0.3, animations: {
            self.selectedSide = side
            if !self.isTagCloudVisible {
                self.layoutChartAndTagsView()
            }
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.finishLayoutChartAndTagsView()
            self.updateTagCloud()
        })
    }

    func updateTagCloud() {
        guard let side = selectedSide else {
            return
        }
        guard let data = homeData else {
            Log.fatal("No home data set")
        }

        let tags = data.dataForSide(side).tags

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
        presenter.displayTag(tag)
    }
}

extension UIButton {

    func configureForTagCloud(tag: String) -> UIButton {
        Log.assert(buttonType == .system)
        setTitle(tag, for: .normal)
        setTitleColor(.darkText, for: .normal)
        titleLabel?.font = .preferredFont(forTextStyle: .title2)
        backgroundColor = .tagBubble
        sizeToFit()
        frame.size.width += 8
        layer.cornerRadius = 6
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
        return self
    }
}
