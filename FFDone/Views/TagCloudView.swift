//
//  TagCloudView.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

// This is a heavily modified version of DBSphereView.swift from
// https://github.com/apparition47/DBSphereTagCloudSwift
//
// The original copyright notice from that file is:
//
//  DBSphereView.swift
//  sphereTagCloud
//
//  Created by Xinbao Dong on 14/8/31.
//  Copyright (c) 2014年 Xinbao Dong. All rights reserved.
//
// However this refers to the original ObjC code; the DBSphereTagCloudSwift
// project on github states it is distributed under the MIT license.
// https://github.com/apparition47/DBSphereTagCloudSwift/blob/master/LICENSE

// The modifications are made to suit FFDone, mostly to provide more flexibility
// in terms of unregistering `CADisplayLink`s and changing the tag cloud without
// creating a new view.  The animations are also changed.  These changes are not
// really in a form for recontribution right now.
//
// We still import the framework for the pieces of SwiftNum that are embedded.

import TMLPresentation
import DBSphereTagCloud_Framework

private struct TagPoint {
    let x: CGFloat
    let y: CGFloat
    let z: CGFloat
}

open class TagCloudView: UIView, UIGestureRecognizerDelegate {

    private var tags = [UIView]()
    private var coordinate = [TagPoint]()
    private var normalDirection = TagPoint(x: 0, y: 0, z: 0)
    private var last = CGPoint.zero
    private var velocity: CGFloat = 0.0
    private var timer: CADisplayLink!
    private var inertia: CADisplayLink!

    // MARK: - initial set

    /**
     *  Sets the cloud's tag views.
     *
     *    @remarks Any @c UIView subview can be passed in the array.
     *
     *  @param array The array of tag views.
     */
    public func setCloudTags(_ array: [UIView]) {

        if !tags.isEmpty {
            clearCloudTags()
        }
        tags = array

        let p1: CGFloat = .pi * (3 - sqrt(5))
        let p2: CGFloat = 2.0 / CGFloat(tags.count)

        for (i, view) in tags.enumerated() {
            addSubview(view)
            view.center = CGPoint(x: bounds.midX, y: bounds.midY)

            let y: CGFloat = CGFloat(i) * p2 - 1 + (p2 / 2)
            let r: CGFloat = sqrt(1 - y * y)
            let p3: CGFloat = CGFloat(i) * p1
            let x: CGFloat = cos(p3) * r
            let z: CGFloat = sin(p3) * r

            let point = TagPoint(x: x, y: y, z: z)
            coordinate.append(point)

            UIView.animate(withDuration: 0.25) {
                self.moveTagView(view, to: point)
            }
        }

        timerStart()
    }

    public func clearCloudTags() {
        tags.forEach { $0.removeFromSuperview() }
        tags = []
        coordinate = []
    }

    /**
     *  Starts the cloud autorotation animation.
     */
    func timerStart() {
        timer.isPaused = false
    }

    /**
     *  Stops the cloud autorotation animation.
     */
    func timerStop() {
        timer.isPaused = true
    }

    private func setup() {
        // pick initial rotation direction
        let a = NSInteger(arc4random() % 10) - 5
        let b = NSInteger(arc4random() % 10) - 5
        normalDirection = TagPoint(x: CGFloat(a), y: CGFloat(b), z: 0)

        let gesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture))
        addGestureRecognizer(gesture)

        inertia = CADisplayLink(target: self, selector: #selector(inertiaStep))
        inertia.add(to: .main, forMode: .default)
        inertia.isPaused = true

        timer = CADisplayLink(target: self, selector: #selector(autoTurnRotation))
        timer.add(to: .main, forMode: .default)
        timer.isPaused = true
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    // MARK: - set frame of point

    func updateAllFrames(angle: CGFloat) {
        for i in 0..<tags.count {
            let point = coordinate[i]

            coordinate[i] = TagPointMakeRotation(point: point, direction: normalDirection, angle: angle)

            moveTagView(tags[i], to: coordinate[i])
        }
    }

    private func moveTagView(_ view: UIView, to point: TagPoint) {
        view.center = CGPoint(x: (point.x + 1) * (bounds.midX), y: (point.y + 1) * bounds.midY)

        let transform: CGFloat = (point.z + 2) / 3
        view.transform = CGAffineTransform.identity.scaledBy(x: transform, y: transform)
        view.layer.zPosition = transform
        view.alpha = transform
        view.isUserInteractionEnabled = point.z >= 0
    }

    // MARK: - autoTurnRotation

    // Hz callback for turning
    @objc func autoTurnRotation() {
        updateAllFrames(angle: 0.002)
    }

    // MARK: - inertia

    func inertiaStart() {
        timerStop()
        inertia.isPaused = false
    }

    func inertiaStop() {
        timerStart()
        inertia.isPaused = true
    }

    // Hz callback for inertia
    @objc func inertiaStep() {
        if velocity <= 0 {
            inertiaStop()
        }
        else {
            velocity -= 70.0
            let angle: CGFloat = velocity / frame.size.width * 2.0 * CGFloat(inertia.duration)
            updateAllFrames(angle: angle)
        }
    }

    // MARK: - gesture selector

    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            last = gesture.location(in: self)
            inertiaStop()
            timerStop()
        }
        else if gesture.state == .changed {
            let current = gesture.location(in: self)
            let direction = TagPoint(x: last.y - current.y, y: current.x - last.x, z: 0)
            let distance: CGFloat = sqrt(direction.x * direction.x + direction.y * direction.y)
            let angle: CGFloat = distance / (frame.size.width / 2.0)
            normalDirection = direction
            updateAllFrames(angle: angle)
            last = current
        }
        else if gesture.state == .ended {
            let velocityP = gesture.velocity(in: self)
            velocity = sqrt(velocityP.x * velocityP.x + velocityP.y * velocityP.y)
            inertiaStart()
        }
    }
}

extension TagCloudView {
    fileprivate func TagPointMakeRotation(point: TagPoint, direction: TagPoint, angle: CGFloat) -> TagPoint {
        if angle == 0 {
            return point
        }

        let temp2 = [[Double(point.x), Double(point.y), Double(point.z), 1], [0,0,0,0], [0,0,0,0], [0,0,0,0]]

        var result = Matrix(temp2)
        if direction.z * direction.z + direction.y * direction.y != 0 {
            let cos1: Double = Double(direction.z / sqrt(direction.z * direction.z + direction.y * direction.y))
            let sin1: Double = Double(direction.y / sqrt(direction.z * direction.z + direction.y * direction.y))
            let t1 = [[1, 0, 0, 0], [0, cos1, sin1, 0], [0, -sin1, cos1, 0], [0, 0, 0, 1]]
            result *= Matrix(t1)
        }

        if direction.x * direction.x + direction.y * direction.y + direction.z * direction.z != 0 {
            let cos2: CGFloat = sqrt(direction.y * direction.y + direction.z * direction.z) / sqrt(direction.x * direction.x + direction.y * direction.y + direction.z * direction.z)
            let sin2: CGFloat = -direction.x / sqrt(direction.x * direction.x + direction.y * direction.y + direction.z * direction.z)
            let t2 = [[Double(cos2), 0, Double(-sin2), 0], [0, 1, 0, 0], [Double(sin2), 0, Double(cos2), 0], [0, 0, 0, 1]]

            result *= Matrix(t2)
        }

        let cos3 = Double(cos(angle))
        let sin3 = Double(sin(angle))
        let t3 = [[cos3, sin3, 0, 0], [-sin3, cos3, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]
        result *= Matrix(t3)

        if direction.x * direction.x + direction.y * direction.y + direction.z * direction.z != 0 {
            let cos2: CGFloat = sqrt(direction.y * direction.y + direction.z * direction.z) / sqrt(direction.x * direction.x + direction.y * direction.y + direction.z * direction.z)
            let sin2: CGFloat = -direction.x / sqrt(direction.x * direction.x + direction.y * direction.y + direction.z * direction.z)
            let t2_ = [[Double(cos2), 0, Double(sin2), 0], [0, 1, 0, 0], [Double(-sin2), 0, Double(cos2), 0], [0, 0, 0, 1]]

            result *= Matrix(t2_)
        }

        if direction.z * direction.z + direction.y * direction.y != 0 {
            let cos1: CGFloat = direction.z / sqrt(direction.z * direction.z + direction.y * direction.y)
            let sin1: CGFloat = direction.y / sqrt(direction.z * direction.z + direction.y * direction.y)
            let t1_ = [[1, 0, 0, 0], [0, Double(cos1), Double(-sin1), 0], [0, Double(sin1), Double(cos1), 0], [0, 0, 0, 1]]

            result *= Matrix(t1_)
        }

        return TagPoint(x: CGFloat(result[0,0]), y: CGFloat(result[0,1]), z: CGFloat(result[0,2]))
    }
}
