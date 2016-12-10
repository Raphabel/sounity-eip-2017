//
//  AroundMe.swift
//  Sounity
//
//  Created by Alix FORNIELES on 10/12/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import MapKit

class EventsAround: NSObject, MKAnnotation {
    let name: String?
    let locationName: String?
    let coordinate: CLLocationCoordinate2D
    let eventID: NSInteger?
    
    init(name: String, locationName: String, coordinate: CLLocationCoordinate2D, eventID: NSInteger) {
        self.name = name
        self.locationName = locationName
        self.coordinate = coordinate
        self.eventID = eventID
        super.init()
    }
    
    var subtitle: String? {
        return locationName
    }
}

class CustomPointAnnotation:MKPointAnnotation {
    var eventID: NSInteger!
    var pinColor: UIColor
    
    init(pinColor: UIColor) {
        self.pinColor = pinColor
        super.init()
    }
}
