//
//  Activity.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 21/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit

class Activity {
    
    // MARK: Properties
    var username : String
    var content: String
    var extra: String
    var pictureAsset: String
    
    /// Init function
    ///
    /// - Parameters:
    ///   - _username: name of the user involved with the activity
    ///   - _content: message of the activity
    ///   - _picture: user's picture involved with the activity
    ///   - _extra: secondary message of the activity
    init(_username: String, _content: String, _picture: String, _extra: String) {
        self.username = _username
        self.content = _content
        self.pictureAsset = _picture
        self.extra = _extra
    }
}
