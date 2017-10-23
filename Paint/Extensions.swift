//
//  Extensions.swift
//  Paint
//
//  Created by Edward Huang on 10/22/17.
//  Copyright © 2017 Eddie Huang. All rights reserved.
//

import Foundation
import SceneKit

public extension Float {
    var radiansToDegrees: Float {
        return self / (Float.pi * 2) * 360
    }
    
    var degreesToRadians: Float {
        return self / 360 * Float.pi * 2
    }
}

public extension SCNVector3 {
    static public func ==(lhs: SCNVector3, rhs: SCNVector3) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
    }
}
