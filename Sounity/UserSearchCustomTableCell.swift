//
//  UserSearchCustomTableCell.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 23/07/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit
import FaveButton

class UserSearchCustomTableCell: UITableViewCell {
    
    @IBOutlet var userPicture: UIImageView!
    @IBOutlet var userName: UILabel!
    @IBOutlet var userUsername: UILabel!
    @IBOutlet weak var startFollowing: FaveButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
