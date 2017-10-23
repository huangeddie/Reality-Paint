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
    
    static public func -(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        let dX = lhs.x - rhs.x
        let dY = lhs.y - rhs.y
        let dZ = lhs.z - rhs.z
        
        return SCNVector3(dX, dY, dZ)
    }
    
    static public func +(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        let sX = lhs.x + rhs.x
        let sY = lhs.y + rhs.y
        let sZ = lhs.z + rhs.z
        
        return SCNVector3(sX, sY, sZ)
    }
    
    static public func /(lhs: SCNVector3, rhs: Float) -> SCNVector3 {
        let sX = lhs.x / rhs
        let sY = lhs.y / rhs
        let sZ = lhs.z / rhs
        
        return SCNVector3(sX, sY, sZ)
    }
    
    static public func *(lhs: SCNVector3, rhs: Float) -> SCNVector3 {
        let sX = lhs.x * rhs
        let sY = lhs.y * rhs
        let sZ = lhs.z * rhs
        
        return SCNVector3(sX, sY, sZ)
    }
    
    static public func *(lhs: Float, rhs: SCNVector3) -> SCNVector3 {
        let sX = rhs.x * lhs
        let sY = rhs.y * lhs
        let sZ = rhs.z * lhs
        
        return SCNVector3(sX, sY, sZ)
    }
}
