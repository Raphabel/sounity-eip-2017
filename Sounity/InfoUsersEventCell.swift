//
//  InfoUsersEventCell.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 01/01/2017.
//  Copyright © 2017 Degraeve Raphaël. All rights reserved.
//

import UIKit
class InfoUsersEventCell: UICollectionViewCell {
    
    var user: UserBasicInfo! {
        didSet {
            self.updateUI()
        }
    }
    
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var pictureUser: UIImageView!
    
    func updateUI() {
        
    }
}
