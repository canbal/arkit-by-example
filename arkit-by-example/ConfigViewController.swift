//
//  ConfigViewController.swift
//  arkit-by-example
//
//  Created by Can Bal on 8/5/17.
//  Copyright © 2017 CB. All rights reserved.
//

import Foundation
import UIKit

class ConfigViewController : UITableViewController {
    @IBOutlet var featurePoints: UISwitch!
    @IBOutlet var worldOrigin: UISwitch!
    @IBOutlet var statistics: UISwitch!
    @IBOutlet var physicsBodies: UISwitch!
    var config: Config = Config()
    
    override func viewWillAppear(_ animated: Bool) {
        featurePoints.isOn = config.showFeaturePoints
        worldOrigin.isOn = config.showWorldOrigin
        statistics.isOn = config.showStatistics
        physicsBodies.isOn = config.showPhysicsBodies
    }
}
