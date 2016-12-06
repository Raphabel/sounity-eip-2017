//
//  descriptionPlaylist.swift
//  Sounity
//
//  Created by Alix FORNIELES on 18/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit

class DescriptionPlaylist: UITableViewCell, UITextFieldDelegate {
    
    @IBOutlet weak var descriptionPlaylist: UITextField!
    
    var descriptionOfPlaylist:String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
