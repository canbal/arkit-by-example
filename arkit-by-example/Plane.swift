//
//  Plane.swift
//  arkit-by-example
//
//  Created by Can Bal on 8/5/17.
//  Copyright © 2017 CB. All rights reserved.
//

import SceneKit
import ARKit

class Plane : SCNNode {
    public var anchor = ARPlaneAnchor()
    public var planeGeometry = SCNBox()
    
    static var transparentMaterial = SCNMaterial()
    static var currentMaterialIndex = 0
    
    init(anchor: ARPlaneAnchor, hidden: Bool, material: SCNMaterial) {
        super.init()
        
        self.anchor = anchor
        let width = anchor.extent.x
        let length = anchor.extent.z
        
        // Using a SCNBox and not SCNPlane to make it easy for the geometry we add to the
        // scene to interact with the plane.
        
        // For the physics engine to work properly give the plane some height so we get interactions
        // between the plane and the gometry we add to the scene
        let planeHeight: Float = 0.01
        planeGeometry = SCNBox(width: CGFloat(width), height: CGFloat(planeHeight), length: CGFloat(length), chamferRadius:0)
        
        // Since we are using a cube, we only want to render the tron grid
        // on the top face, make the other sides transparent
        Plane.transparentMaterial.diffuse.contents = UIColor(white:1.0, alpha:0.0)
        
        if (hidden) {
            self.planeGeometry.materials = [Plane.transparentMaterial, Plane.transparentMaterial, Plane.transparentMaterial, Plane.transparentMaterial, Plane.transparentMaterial, Plane.transparentMaterial]
        } else {
            self.planeGeometry.materials = [Plane.transparentMaterial, Plane.transparentMaterial, Plane.transparentMaterial, Plane.transparentMaterial, material, Plane.transparentMaterial]
        }
        
        let planeNode = SCNNode(geometry: self.planeGeometry)
        planeNode.position = SCNVector3(0, -planeHeight / 2, 0)

        // Give the plane a physics body so that items we add to the scene interact with it
        planeNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: planeGeometry, options: nil))
        
        setTextureScale()
        addChildNode(planeNode)
    }
    
    public func update(anchor: ARPlaneAnchor) {
        // As the user moves around the extend and location of the plane
        // may be updated. We need to update our 3D geometry to match the
        // new parameters of the plane.
        planeGeometry.width = CGFloat(anchor.extent.x)
        planeGeometry.length = CGFloat(anchor.extent.z)
        
        // When the plane is first created it's center is 0,0,0 and the nodes
        // transform contains the translation parameters. As the plane is updated
        // the planes translation remains the same but it's center is updated so
        // we need to update the 3D geometry position
        position = SCNVector3(anchor.center.x, 0, anchor.center.z)
        
        let node = childNodes.first
        node?.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: planeGeometry, options: nil))
        
        setTextureScale()
    }
    
    public func setTextureScale() {
        let width = planeGeometry.width
        let height = planeGeometry.length
        
        // As the width/height of the plane updates, we want our tron grid material to
        // cover the entire plane, repeating the texture over and over. Also if the
        // grid is less than 1 unit, we don't want to squash the texture to fit, so
        // scaling updates the texture co-ordinates to crop the texture in that case
        let material = planeGeometry.materials[4]
        let transform = SCNMatrix4MakeScale(Float(width), Float(height), 1)
        material.diffuse.contentsTransform = transform
        material.roughness.contentsTransform = transform
        material.metalness.contentsTransform = transform
        material.normal.contentsTransform = transform
    }
    
    public func hide() {
        planeGeometry.materials = [Plane.transparentMaterial, Plane.transparentMaterial, Plane.transparentMaterial, Plane.transparentMaterial, Plane.transparentMaterial, Plane.transparentMaterial]
    }
    
    public func reveal() {
        planeGeometry.materials = [Plane.transparentMaterial, Plane.transparentMaterial, Plane.transparentMaterial, Plane.transparentMaterial, Plane.currentMaterial(), Plane.transparentMaterial]
    }
    
    public func changeMaterial() {
        // Static, all future planes use this to have the same material
        Plane.currentMaterialIndex = (Plane.currentMaterialIndex + 1) % 5
        
        let transform = planeGeometry.materials[4].diffuse.contentsTransform
        let material = Plane.currentMaterial()
        material.diffuse.contentsTransform = transform
        material.roughness.contentsTransform = transform
        material.metalness.contentsTransform = transform
        material.normal.contentsTransform = transform
        planeGeometry.materials = [Plane.transparentMaterial, Plane.transparentMaterial, Plane.transparentMaterial, Plane.transparentMaterial, material, Plane.transparentMaterial]
    }
    
    public static func currentMaterial() -> SCNMaterial {
        var materialName: String? = nil
        switch (Plane.currentMaterialIndex) {
        case 0:
            materialName = "tron"
            break
        case 1:
            materialName = "oakfloor2"
            break
        case 2:
            materialName = "sculptedfloorboards"
            break
        case 3:
            materialName = "granitesmooth"
            break
        case 4:
            return Plane.transparentMaterial
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
