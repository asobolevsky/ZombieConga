//
//  CGFloat+Extension.swift
//  ZombieConga
//
//  Created by Alexey Sobolevsky on 27/09/2019.
//  Copyright © 2019 Alexey Sobolevsky. All rights reserved.
//

import CoreGraphics

extension CGFloat {

    static var random: CGFloat {
        return CGFloat(Float(arc4random()) / Float(UInt32.max))
    }

    static func random(min: CGFloat, max: CGFloat) -> CGFloat {
        assert(min < max)
        return .random * (max - min) + min
    }

}
