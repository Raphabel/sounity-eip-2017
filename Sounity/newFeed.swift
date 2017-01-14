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
    
    /// Init class with an event
    ///
    /// - Parameters:
    ///   - _message: main message of the news
    ///   - _picture: main picture of the news
    ///   - _created_date: creation date of the news
    ///   - _event: event's info related the news
    ///   - _user: user's info related to the news
    init(_message: String, _picture: String, _created_date: String, _event: Event, _user: User) {
        self.message = _message
        self.picture = _picture
        self.created_date = _created_date
        self.eventInfo = _event
        self.user = _user
    }
    
    /// Init class with a follower
    ///
    /// - Parameters:
    ///   - _message: main message of the news
    ///   - _picture: main picture of the news
    ///   - _created_date: creation date of the news
    ///   - _follower: follower info related the news
    ///   - _user: user's info related to the news
    init(_message: String, _picture: String, _created_date: String, _follower: Followers, _user: User) {
        self.message = _message
        self.picture = _picture
        self.created_date = _created_date
        self.followerInfo = _follower
        self.user = _user
    }
    
    /// Init class with basic info
    ///
    /// - Parameters:
    ///   - _message: main message of the news
    ///   - _picture: main picture of the news
    ///   - _created_date: creation date of the news
    ///   - _user: user's info related to the news
    init(_message: String, _picture: String, _created_date: String, _user: User) {
        self.message = _message
        self.picture = _picture
        self.created_date = _created_date
        self.user = _user
    }
}
