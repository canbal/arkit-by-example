//
//  PBRMaterial.swift
//  arkit-by-example
//
//  Created by Can Bal on 8/5/17.
//  Copyright © 2017 CB. All rights reserved.
//

import Foundation
import SceneKit

class PBRMaterial {
    static var materials = Dictionary<String, SCNMaterial>()
    static let assetsPath = "./Assets.scnassets/Materials"
    
    static func materialNamed(name: String) -> SCNMaterial {
        var mat = PBRMaterial.materials[name]
        if (mat == nil) {
            mat = SCNMaterial()
            mat!.lightingModel = .physicallyBased
            mat!.diffuse.contents = UIImage(named: "\(PBRMaterial.assetsPath)/\(name)/\(name)-albedo.png")
            mat!.roughness.contents = UIImage(named: "\(PBRMaterial.assetsPath)/\(name)/\(name)-roughness.png")
            mat!.metalness.contents = UIImage(named: "\(PBRMaterial.assetsPath)/\(name)/\(name)-metal.png")
            mat!.normal.contents = UIImage(named: "\(PBRMaterial.assetsPath)/\(name)/\(name)-normal.png")
            mat!.diffuse.wrapS = .repeat
            mat!.diffuse.wrapT = .repeat
            mat!.roughness.wrapS = .repeat
            mat!.roughness.wrapT = .repeat
            mat!.metalness.wrapS = .repeat
            mat!.metalness.wrapT = .repeat
            mat!.normal.wrapS = .repeat
            mat!.normal.wrapT = .repeat
            PBRMaterial.materials[name] = mat!
        }
        return mat!
    }
}
