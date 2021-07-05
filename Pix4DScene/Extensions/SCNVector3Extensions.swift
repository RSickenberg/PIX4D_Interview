//
//  SCNVector3Extensions.swift
//  Pix4DScene
//
//  Created by Romain Sickenberg on 4.07.21.
//

import Foundation
import SceneKit

extension SCNVector3 {
    // https://stackoverflow.com/a/47241952/6914561
    static func +(lhv:SCNVector3, rhv:SCNVector3) -> SCNVector3 {
        return SCNVector3(lhv.x + rhv.x, lhv.y + rhv.y, lhv.z + rhv.z)
    }
}
