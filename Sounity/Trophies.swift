//
//  Trophies.swift
//  Sounity
//
//  Created by Alix FORNIELES on 08/01/2017.
//  Copyright © 2017 Degraeve Raphaël. All rights reserved.
//

import Foundation

import UIKit

class Trophies {
    
    // MARK: Properties
    var id: Int
    var name: String
    var desc: String
    var score: Int
    var level: Int
    
    init(id: Int, name: String, desc: String, score: Int, level: Int) {
        self.id = id
        self.name = name
        self.desc = desc
        self.score = score
        self.level = level
    }
}
