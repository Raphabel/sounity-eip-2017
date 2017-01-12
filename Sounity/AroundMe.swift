//
//  AroundMe.swift
//  Sounity
//
//  Created by Alix FORNIELES on 10/12/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import MapKit

/// Class related to the AroundMeViewController
class EventsAround: NSObject, MKAnnotation {
    let name: String?
    let locationName: String?
    let coordinate: CLLocationCoordinate2D
    let eventID: NSInteger?
    
    /// Init function for the class
    ///
    /// - Parameters:
    ///   - name: event's location
    ///   - locationName: location's event
    ///   - coordinate: coordinate's event
    ///   - eventID: event's  ID
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

/// Class related to the AroundMeViewController in order to customise MKPointAnnotation
class CustomPointAnnotation:MKPointAnnotation {
    var eventID: NSInteger!
    var pinColor: UIColor
    
    /// Init function for the class
    ///
    /// - Parameter pinColor: Color to put on the custom MKPointAnnotation
    init(pinColor: UIColor) {
        self.pinColor = pinColor
        super.init()
    }
}
