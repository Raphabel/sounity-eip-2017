//
//  MusicPlayEvent.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 18/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation

class MusicPlaylistEvent {
    var title: String
    var artist: String
    var cover: String
    var url: String
    var addedBy: String
    var addedAt: String
    
    var like: Int
    var dislike: Int
    var apiId: Int
    var id: Int
    
    var liked: Bool
    var disliked: Bool
    
    var duration: Double
    
    /// Init class without argument
    init() {
        self.title = ""
        self.artist = ""
        self.cover = ""
        self.url = ""
        self.addedAt = ""
        self.addedBy = ""
        
        self.like = -1
        self.dislike = -1
        self.apiId = -1
        self.id = -1
        
        self.liked = false
        self.disliked = false
        
        self.duration = -1
    }
    
    /// Init class with music
    ///
    /// - Parameters:
    ///   - _id: id of the music
    ///   - _apiId: api id of the music
    ///   - _artist: music's artist
    ///   - _title: music's title
    ///   - _url: music's url
    ///   - _cover: music's cover
    ///   - _duration: music's duration
    ///   - _addedBy: the user's nickname who added the music
    ///   - _addedAt: the time when the music was added
    ///   - _like: number of likes related to the music
    ///   - _dislike: number of dislikes related to the music
    ///   - _liked: is the current user has already liked the music
    ///   - _disliked: is the current user has already disliked the music
    init(_id: Int, _apiId: Int, _artist: String, _title: String, _url: String, _cover: String, _duration: Double, _addedBy: String, _addedAt: String, _like: Int, _dislike: Int, _liked: Bool, _disliked: Bool) {
        self.title = _title
        self.addedAt = _addedAt
        self.like = _like
        self.apiId = _apiId
        self.id = _id
        self.dislike = _dislike
        self.artist = _artist
        self.duration = _duration
        self.cover = _cover
        self.url = _url
        self.addedBy = _addedBy
        self.liked = _liked
        self.disliked = _disliked
    }
}
