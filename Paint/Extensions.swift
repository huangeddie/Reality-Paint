//
//  Extensions.swift
//  Paint
//
//  Created by Edward Huang on 10/22/17.
//  Copyright © 2017 Eddie Huang. All rights reserved.
//

import Foundation

public extension Float {
    var radiansToDegrees: Float {
        return self / (Float.pi * 2) * 360
    }
    
    var degreesToRadians: Float {
        return self / 360 * Float.pi * 2
    }
}
