//
//  SounityStartTrophiesTableViewCell.swift
//  Sounity
//
//  Created by Alix FORNIELES on 07/01/2017.
//  Copyright © 2017 Degraeve Raphaël. All rights reserved.
//

import UIKit

class TrophiesTableViewCell: UITableViewCell {

    @IBOutlet weak var Name: UILabel!
    @IBOutlet weak var descriptionTrophies: UILabel!
    @IBOutlet weak var levelNumber: UILabel!
    @IBOutlet weak var levelImage: UIImageView!
    
    @IBOutlet weak var level1: UIImageView!
    @IBOutlet weak var level2: UIImageView!
    @IBOutlet weak var level3: UIImageView!
    @IBOutlet weak var level4: UIImageView!
    @IBOutlet weak var level5: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
