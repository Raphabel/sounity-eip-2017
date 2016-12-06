//
//  Event.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 10/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

//
//  Event.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 10/09/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation

class Event {
    
    var id: Int = 0
    var user_max: Int = 0
    
    var latitude: Double = 48.85341
    var longitude: Double = 2.3488
    
    var started: Bool = true
    var publicEvent: Bool = true
    var isOwner: Bool = true
    var isAdmin: Bool = true
    
    var name: String = ""
    var description: String = ""
    var picture: String = ""
    var create_date: String = ""
    var expired_date: String = ""
    var location_name: String = ""
    
    init(_id: Int, _userMax: Int, _lat: Double, _long: Double, _started: Bool, _public: Bool, _name: String, _desc: String, _picture: String, _created: String, _expired: String, _locationName: String, _isOwner: Bool, _isAdmin: Bool) {
        self.id = _id
        self.user_max = _userMax
        
        self.latitude = _lat
        self.longitude = _long
        
        self.started = _started
        self.publicEvent = _public
        self.isAdmin = _isAdmin
        self.isOwner = _isOwner
        
        self.name = _name
        self.description = _desc
        self.picture = _picture
        self.create_date = _created
        self.expired_date = _expired
        self.location_name = _locationName
    }
}