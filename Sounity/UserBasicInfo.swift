//
//  UserBasicInfo.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 13/01/2017.
//  Copyright © 2017 Degraeve Raphaël. All rights reserved.
//

import Foundation

class UserBasicInfo {
    var nickname: String
    var picture: String
    
    var id: Int
    
    var owner: Bool
    var admin: Bool
    var banned: Bool
    var participating: Bool
    var adminMode: Bool
    
    /// Init class with datas for users manager
    ///
    /// - Parameters:
    ///   - _nickname: nickname user
    ///   - _id: id suer
    ///   - _picture: pictur user
    ///   - _banned: is the user banned from the event
    ///   - _participating: is the user participating to the event
    init(_nickname: String, _id: Int, _picture: String, _banned: Bool, _participating: Bool) {
        self.nickname = _nickname
        self.id = _id
        self.picture = _picture
        self.banned = _banned
        self.participating = _participating
        
        self.admin = false
        self.owner = false
        self.adminMode = false
    }
    
    /// Init class with datas for admins manager
    ///
    /// - Parameters:
    ///   - _nickname: nickname user
    ///   - _id: id suer
    ///   - _picture: pictur user
    ///   - _owner: is the user owner of the event
    ///   - _admin: is the user admin of the event
    init(_nickname: String, _id: Int, _picture: String, _owner: Bool, _admin: Bool) {
        self.nickname = _nickname
        self.id = _id
        self.picture = _picture
        self.owner = _owner
        self.admin = _admin
        self.banned = false
        self.participating = false
        self.adminMode = true
    }
}
