//
//  MusicSearchCustomTableCell.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 18/07/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit

class MusicSearchCustomTableCell: UITableViewCell {
    
    @IBOutlet var trackPicture: UIImageView!
    @IBOutlet var trackTitle: UILabel!
    @IBOutlet var trackArtist: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
