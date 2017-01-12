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
    
    /// Init class without arguments
    init() {
        self.message = ""
        self.picture = ""
        self.nickname = ""
        self.time = ""
    }
    
    /// Init class
    ///
    /// - Parameters:
    ///   - _message: content message
    ///   - _picture: picture of the user creator
    ///   - _nickname: nickname of the user creator
    ///   - _time: creation time of the message 
    init(_message: String, _picture: String, _nickname: String, _time: String) {
        self.message = _message
        self.picture = _picture
        self.nickname = _nickname
        self.time = _time
    }
}
