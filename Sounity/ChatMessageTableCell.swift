//
//  ChatMessageTableCell.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 17/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit

class ChatMessageTableCell: UITableViewCell {
    
    
    @IBOutlet var viewOtherUser: UIView!
    @IBOutlet var pictureOtherUser: UIImageView!
    @IBOutlet var timeOther: UILabel!
    @IBOutlet var nicknameOther: UILabel!
    @IBOutlet var messageOther: UILabel!
    
    
    @IBOutlet var viewOwnUser: UIView!
    @IBOutlet var pictureOwnUser: UIImageView!
    @IBOutlet var timeOwn: UILabel!
    @IBOutlet var nicknameOwn: UILabel!
    @IBOutlet var messageOwn: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
