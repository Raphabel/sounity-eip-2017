//
//  MusicProvider.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 13/10/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class MusicProvider: NSObject {
    
    static let sharedInstance = MusicProvider()
    
    var name: String = SounityAPI.PROVIDER_MUSIC.DEEZER.rawValue
    var apiId: Int = 2
    
    var allMusicProviders = [MusicProviderInfo]()
    
    override init() {
        super.init()
    }
    
    func getProviderByName(_ provider: SounityAPI.PROVIDER_MUSIC) {
        let api = SounityAPI()
        
        Alamofire.request(api.getRoute(SounityAPI.ROUTES.PROVIDERS_MUSIC), method: .get)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    for (_,subJson):(String, JSON) in jsonResponse {
                        self.allMusicProviders.append(MusicProviderInfo(_name: subJson["name"].stringValue, _id: subJson["id"].intValue))
                        
                        if (subJson["name"].stringValue == provider.rawValue) {
                            self.name = provider.rawValue
                            self.apiId = subJson["id"].intValue
                        }
                    }
                }
        }
    }
    
    func getUrlTrackByMusicProvider(_ _idTrack: String, _apiId: Int) -> String {
        var urlFinal = ""
        
        for object in allMusicProviders {
            if (object.id == _apiId) {
                if (object.name == SounityAPI.PROVIDER_MUSIC.SOUNDCLOUD.rawValue) {
                    urlFinal = SouncloudAPIRoutes.TRACK.rawValue + _idTrack + "?client_id=" + SouncloudAPIRoutes.CLIENT_ID.rawValue
                }
                else if (object.name == SounityAPI.PROVIDER_MUSIC.DEEZER.rawValue) {
                    urlFinal = DeezerAPIRoutes.TRACK.rawValue + _idTrack
                }
            }
        }
        return urlFinal
    }
    
    func getUrlStreamByMusicProvider(_ _urlStream: String, _apiId: Int) -> String {
        var urlFinal = ""
        
        for object in allMusicProviders {
            if (object.id == _apiId) {
                if (object.name == SounityAPI.PROVIDER_MUSIC.SOUNDCLOUD.rawValue) {
                    urlFinal = _urlStream + "?client_id=" + SouncloudAPIRoutes.CLIENT_ID.rawValue
                }
                else if (object.name == SounityAPI.PROVIDER_MUSIC.DEEZER.rawValue) {
                    urlFinal = _urlStream
                }
            }
        }
        return urlFinal
    }
    
    func getNameMusicProviderById(_ _apiId: Int) -> String {
        var nameMusicProvider = ""
        
        for object in allMusicProviders {
            if (object.id == _apiId) {
                nameMusicProvider = object.name
            }
        }
        
        return nameMusicProvider
    }
}

class MusicProviderInfo {
    var name: String = ""
    var id: Int = -1
    
    init(_name: String, _id: Int) {
        self.name = _name
        self.id = _id
    }
}
