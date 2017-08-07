//
//  CollisionCategory.swift
//  arkit-by-example
//
//  Created by Can Bal on 8/5/17.
//  Copyright © 2017 CB. All rights reserved.
//

struct CollisionCategory : OptionSet {
    let rawValue: Int
    
    static let bottom  = CollisionCategory(rawValue: 1 << 0)
    static let cube = CollisionCategory(rawValue: 1 << 1)
}
