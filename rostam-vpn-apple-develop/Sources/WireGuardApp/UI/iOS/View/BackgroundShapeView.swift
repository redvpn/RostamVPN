// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit

class BackgroundShapeView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        isOpaque = true
        backgroundColor = .white
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!

        let arcHeight = CGFloat(30)
        let topRect = CGRect(origin: rect.origin, size: CGSize(width: rect.width, height: rect.height - arcHeight))
        let rectPath = UIBezierPath(rect: topRect).cgPath

        context.addPath(rectPath)
        UIColor.clear.setFill()
        context.fill(topRect)

        let arcRect = CGRect(
            x: topRect.origin.x,
            y: topRect.origin.y + topRect.height,
            width: topRect.width,
            height: arcHeight)

        let arcRadius = (arcRect.height / 2) + pow(arcRect.width, 2) / (8 * arcRect.height)
        let arcCenter = CGPoint(
            x: arcRect.origin.x + arcRect.width / 2,
            y: arcRect.origin.y - arcRadius)
        let angle = acos(arcRect.width / (2 * arcRadius))
        let startAngle = CGFloat(Angle(degrees: 180).toRadians()) + angle
        let endAngle = CGFloat(Angle(degrees: 360).toRadians()) - angle

        let arcPath = CGMutablePath()
        arcPath.addArc(
            center: arcCenter,
            radius: arcRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true)

        context.addPath(arcPath)

        UIColor.lightAzure.setFill()
        context.fillPath()
    }
}

typealias Angle = Measurement<UnitAngle>

extension Measurement where UnitType == UnitAngle {
    init(degrees: Double) {
        self.init(value: degrees, unit: .degrees)
    }

    func toRadians() -> Double {
        return converted(to: .radians).value
    }
}
