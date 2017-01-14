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
    
    var user: User! {
        didSet {
            self.updateUI()
        }
    }
    
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
    
    func updateUI() {
        startFollowing.isSelected = false
        userName.text = "\(user.first_name.uppercaseFirst) \(user.last_name.uppercaseFirst)"
        userUsername.text = user.nickname.uppercaseFirst
        
        if (user.picture == "") {
            userPicture.image = UIImage(named: "UnknownUserCover")!
        }
        else if (Reachability.isConnectedToNetwork() == true) {
            userPicture.load.request(with: user.picture, onCompletion: { image, error, operation in
                if (self.userPicture.image?.size == nil) {
                    self.userPicture.image = UIImage(named: "emptyPicture")
                }
                MakeElementRounded().makeElementRounded(self.userPicture, newSize: self.userPicture.frame.width)
            })
            
            
        }
    }
}
