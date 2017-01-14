//
//  EventSearchCustomTableCell.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 26/07/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit

class EventSearchCustomTableCell: UITableViewCell {
    
    var event: Event! {
        didSet {
            self.updateUI()
        }
    }
    
    @IBOutlet var eventPicture: UIImageView!
    @IBOutlet var eventName: UILabel!
    @IBOutlet var eventLocationName: UILabel!
    @IBOutlet var eventStarted: UISwitch!
    @IBOutlet var rightsOnEvent: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func updateUI() {
        eventName.text = "\(event.name.uppercaseFirst)"
        eventLocationName.text = "\(event.location_name.uppercaseFirst)"
        if (event.started == true) {
            eventStarted.isOn = true;
        }
        
        if (event.isOwner) {
            rightsOnEvent.image = UIImage(named: "OwnerEvent")!
        } else if (event.isOwner) {
            rightsOnEvent.image = UIImage(named: "AdminEvent")!
        } else {
            rightsOnEvent.isHidden = true
        }
        
        if (event.picture == "") {
            eventPicture.image = UIImage(named: "UnknownEventCover")!
        }
        else if (Reachability.isConnectedToNetwork() == true) {
            eventPicture.load.request(with: event.picture, onCompletion: { image, error, operation in
                if (self.eventPicture.image?.size == nil) {
                    self.eventPicture.image = UIImage(named: "emptyPicture")
                }
                MakeElementRounded().makeElementRounded(self.eventPicture, newSize: self.eventPicture.frame.width)
            })
        }
    }
}
