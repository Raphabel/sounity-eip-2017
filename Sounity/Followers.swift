//
//  Followers.swift
//  Sounity
//
//  Created by Alix FORNIELES on 07/10/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation

class Followers  {

    var id: Int?
    var lastName: String?
    var nickname: String?
    var followedAt: String?
    var firstName: String?
    var picture:String?
    var follow: Bool?
    
    init(_id: Int, _lastName: String, _nickName: String, _followedAt: String, _firstName: String, _picture: String, _follow: Bool) {
        
        self.id = _id
        self.lastName = _lastName
        self.nickname = _nickName
        self.followedAt = _followedAt
        self.firstName = _firstName
        self.picture = _picture
        self.follow = _follow
    }
}