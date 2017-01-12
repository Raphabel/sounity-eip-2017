//
//  newFeed.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 12/01/2017.
//  Copyright © 2017 Degraeve Raphaël. All rights reserved.
//

import Foundation

// MARK: Class NewFeed
class newFeed {
    var message: String = ""
    var picture: String = ""
    var created_date: String = ""
    
    var eventInfo: Event?
    var followerInfo: Followers?
    var user: User
    
    init(_message: String, _picture: String, _created_date: String, _event: Event, _user: User) {
        self.message = _message
        self.picture = _picture
        self.created_date = _created_date
        self.eventInfo = _event
        self.user = _user
    }
    
    init(_message: String, _picture: String, _created_date: String, _follower: Followers, _user: User) {
        self.message = _message
        self.picture = _picture
        self.created_date = _created_date
        self.followerInfo = _follower
        self.user = _user
    }
    
    init(_message: String, _picture: String, _created_date: String, _user: User) {
        self.message = _message
        self.picture = _picture
        self.created_date = _created_date
        self.user = _user
    }
}
