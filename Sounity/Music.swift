//
//  Musics.swift
//  Sounity
//
//  Created by Alix FORNIELES on 12/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit

class Music {
    // MARK: Properties
    
    var title : String
    var artist: String
    var IDMusic: Int
    var apiId: Int
    var played: Bool
    var cover: String
    var duration: Double
    var id: Int
    
    // MARK: Initialization
    
    init(id: Int, title: String, artist: String, IDMusic: Int, apiId: Int, played: Bool, cover: String) {
        self.id = id
        self.title = title
        self.artist = artist
        self.IDMusic = IDMusic
        self.apiId = apiId
        self.played = played
        self.cover = cover
        self.duration = 0
    }
    
    init(id: Int, title: String, artist: String, IDMusic: Int, apiId: Int, played: Bool, cover: String, duration: Double) {
        self.id = id
        self.title = title
        self.artist = artist
        self.IDMusic = IDMusic
        self.apiId = apiId
        self.played = played
        self.cover = cover
        self.duration = duration
    }
}
