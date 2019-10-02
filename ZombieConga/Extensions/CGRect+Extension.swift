//
//  CGRect+Extension.swift
//  ZombieConga
//
//  Created by Alexey Sobolevsky on 18/09/2019.
//  Copyright © 2019 Alexey Sobolevsky. All rights reserved.
//

import CoreGraphics

extension CGRect {

    func scaled(by factor: CGFloat) -> CGRect {
        let scaledSize = CGSize(width: size.width * factor, height: size.height * factor)
        return CGRect(origin: origin, size: scaledSize)
    }

}

