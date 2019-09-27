//
//  CGPoint+Extension.swift
//  ZombieConga
//
//  Created by Alexey Sobolevsky on 27/09/2019.
//  Copyright © 2019 Alexey Sobolevsky. All rights reserved.
//

import CoreGraphics

extension CGPoint {

    var vector: CGVector {
        return CGVector(dx: x, dy: y)
    }

    static func randomPoint(in rect: CGRect) -> CGPoint {
        return CGPoint(
            x: CGFloat.random(min: rect.minX, max: rect.maxX),
            y: CGFloat.random(min: rect.minY, max: rect.maxY)
        )
    }

}
