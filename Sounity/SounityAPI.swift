//
//  apiSounity.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 16/07/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation

class SounityAPI {
    enum ROUTES: String {
        case LOGIN = "/login"
        case TOKEN = "/token"
        case CREATE_USER = "/user"
        case CHECK_NICKNAME = "/user/check/nickname"
        case COUNTRIES = "/countries"
        case LANGUAGES = "/languages"
        case SEARCH_MUSIC = "/search/music"
        case SEARCH_USER = "/search"
        case GET_INFO_EVENT = "/event/"
        case CREATE_EVENT = "/event"
        case GET_ALL_EVENTS = "/events"
        case PLAYLIST_USER = "/playlist"
        case PLAYLIST_USER_DELETE = "/playlist/"
        case PROVIDERS_MUSIC = "/musicProviders"
        case TIMELINE = "/newsfeed"
        case TROPHIES = "/trophies/"
        case SMART = "/smart"
    }
    
    enum SOCKET: String {
        case NEW_MESSAGE = "chat:newmessage"
        case MUSIC_ADDED = "music:added"
        case MUSIC_LIKED = "music:liked"
        case MUSIC_PLAY = "music:play"
        case MUSIC_PAUSE = "music:pause"
        case MUSIC_NEXT = "music:next"
        case MUSIC_PLAYED = "music:played"
        case MUSIC_PAUSED = "music:paused"
        case MUSIC_CHANGED = "music:changed"
        case NEW_JOINED = "event:joined"
        case BANNED = "event:banned"
        case LEFT = "event:left"
        case STOP = "event:stopped"
        case BAN = "event:ban"
    }
    
    enum PROVIDER_MUSIC: String {
        case DEEZER = "deezer"
        case SOUNDCLOUD = "soundcloud"
    }
    
    enum API: String {
        case DEMO = "https://apidemo.sounity.com" // pre-production
        case DEV = "https://apidev.sounity.com" // development
        case PROD = "https://api.sounity.com" // production
    }
    
    func getRoute(_ route: ROUTES) -> String {
        return ("\(API.DEMO.rawValue)\(route.rawValue)");
    }
}
