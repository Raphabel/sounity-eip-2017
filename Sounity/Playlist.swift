//
//  Playlist.swift
//  Sounity
//
//  Created by Alix FORNIELES on 01/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit

class Playlist {
    // MARK: Properties
    
    var name: String
    var create_date: String
    var id: Int
    var desc: String
    var picture: String = ""
    
    init(name: String, create_date: String, id: Int, desc: String, _picture: String) {
        self.name = name
        self.create_date = create_date
        self.id = id
        self.desc = desc
        self.picture = _picture
    }
}

struct idMusic {
    static var id_music = 0
}