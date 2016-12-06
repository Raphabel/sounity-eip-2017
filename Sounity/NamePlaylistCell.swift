//
//  NamePlaylist.swift
//  Sounity
//
//  Created by Alix FORNIELES on 18/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit

class NamePlaylist: UITableViewCell, UITextFieldDelegate{

    @IBOutlet weak var namePlaylist: UITextField!
    @IBOutlet weak var imagePlaylist: UIImageView!
    
    var nameOfPlaylist:String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
  }