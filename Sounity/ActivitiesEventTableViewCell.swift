//
//  ActivitiesEventTableViewCell.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 21/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit

class ActivitiesEventTableViewCell: UITableViewCell {
    
    var activity: Activity! {
        didSet {
            self.updateUI()
        }
    }
    
    // MARK: Infos user connected
    var user = UserConnect()
    
    @IBOutlet var username: UILabel!
    @IBOutlet var content: UILabel!
    @IBOutlet var extra: UILabel!
    @IBOutlet var picture: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func updateUI() {
        username.text = activity.username == self.user.username ? "You" : activity.username
        content.text = activity.content
        extra.text = activity.extra
        picture.image = UIImage(named: activity.pictureAsset)!
    }

}
