//
//  EventSearchCustomTableCell.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 26/07/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit

class EventSearchCustomTableCell: UITableViewCell {
    
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
}
