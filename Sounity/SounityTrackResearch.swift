//
//  SounityTrack.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 02/10/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import SwiftyJSON
import Alamofire

class SounityTrackResearch {
    
    var idTrack: Int = 0
    
    var streamLink: String = ""
    var previewStream: String = ""
    var title: String = ""
    var artist: String = ""
    var cover: String = ""
    var type: String = ""
    
    var idAPI: Int = 0
    
    var duration: Double = 0
    
    var preview: Bool = false
    
    init() {
        self.idTrack = 0
        self.streamLink = ""
        self.previewStream = ""
        self.title = ""
        self.artist = ""
        self.cover = ""
        self.type = ""
        self.idAPI = 0
        self.duration = 0
        self.preview = false
    }
    
    init(_jsonResponse: JSON, _music_provider: String, _apiId: Int) {
        self.idAPI = _apiId
        
        if (_music_provider == SounityAPI.PROVIDER_MUSIC.DEEZER.rawValue) {
            getInfoFromDeezer(_jsonResponse)
        }
        else if (_music_provider == SounityAPI.PROVIDER_MUSIC.SOUNDCLOUD.rawValue) {
            getInfoFromSoundcloud(_jsonResponse)
        }
    }
    
    fileprivate func getInfoFromSoundcloud (_ _jsonResponse: JSON) {
        self.idTrack = _jsonResponse["id"].intValue
        self.streamLink = _jsonResponse["stream_url"].stringValue
        self.title = _jsonResponse["title"].stringValue
        self.artist = _jsonResponse["artist"].stringValue
        self.cover = _jsonResponse["artwork_url"].stringValue
        self.type = _jsonResponse["genre"].stringValue 
        self.duration =  (_jsonResponse["duration"].double! / 1000)
    }
    
    fileprivate func getInfoFromDeezer (_ _jsonResponse: JSON) {
        let albumObject = _jsonResponse["album"]
        let artistObject = _jsonResponse["artist"]

        self.preview = true
        self.idTrack = _jsonResponse["id"].intValue
        self.streamLink = _jsonResponse["preview"].stringValue
        self.title = _jsonResponse["title"].stringValue
        self.artist = artistObject["name"].stringValue == "" ? _jsonResponse["artist"].stringValue : artistObject["name"].stringValue
        self.cover = _jsonResponse["cover"].exists() ? _jsonResponse["cover"].stringValue : albumObject["cover"].stringValue
        self.type = _jsonResponse["type"].stringValue
        self.duration =  (_jsonResponse["duration"].doubleValue)
    }
}
