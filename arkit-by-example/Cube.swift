//
//  Cube.swift
//  arkit-by-example
//
//  Created by Can Bal on 8/5/17.
//  Copyright © 2017 CB. All rights reserved.
//

import Foundation
import SceneKit

class Cube : SCNNode {
    static var currentMaterialIndex = 0
    
    init(position: SCNVector3, material: SCNMaterial) {
        super.init()
        
        let dimension: CGFloat = 0.2
        let cube = SCNBox(width: dimension, height: dimension, length: dimension, chamferRadius: 0)
        cube.materials = [material]
        let node = SCNNode(geometry: cube)
        
        // The physicsBody tells SceneKit this geometry should be manipulated by the physics engine
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        node.physicsBody?.mass = 2.0
        node.physicsBody?.categoryBitMask = CollisionCategory.cube.rawValue
        node.position = position
        
        addChildNode(node)
    }
    
    public func changeMaterial() {
        // Static, all future cubes use this to have the same material
        Cube.currentMaterialIndex = (Cube.currentMaterialIndex + 1) % 4
        childNodes.first?.geometry?.materials = [Cube.currentMaterial()]
    }
    
    public static func currentMaterial() -> SCNMaterial {
        var materialName: String? = nil
        switch (Cube.currentMaterialIndex) {
        case 0:
            materialName = "rustediron-streaks"
            break
        case 1:
            materialName = "carvedlimestoneground"
            break
        case 2:
            materialName = "granitesmooth"
            break
        case 3:
            materialName = "old-textured-fabric"
            break
        default:
            materialName = "old-textured-fabric"
            break
        }
        return PBRMaterial.materialNamed(name: materialName!).copy() as! SCNMaterial
    }
    
    public func remove() {
        removeFromParentNode()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
