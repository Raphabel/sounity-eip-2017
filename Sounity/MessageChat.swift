//
//  MessageChat.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 17/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation

class MessageChat {
    var message: String
    var picture: String
    var nickname: String
    var time: String
    
    init() {
        self.message = ""
        self.picture = ""
        self.nickname = ""
        self.time = ""
    }
    
    init(_message: String, _picture: String, _nickname: String, _time: String) {
        self.message = _message
        self.picture = _picture
        self.nickname = _nickname
        self.time = _time
    }
}