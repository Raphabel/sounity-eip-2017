//
//  SearchMusicEventCustomCell.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 18/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation
import UIKit

class SearchMusicEventCustomTableCell: UITableViewCell {
    
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
