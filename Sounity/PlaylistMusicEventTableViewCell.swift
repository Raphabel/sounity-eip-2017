//
//  PlaylistMusicEventTableViewCell.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 18/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation

//
//  SearchMusicEventCustomCell.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 18/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation
import UIKit

class PlaylistMusicEventTableViewCell: UITableViewCell {
    
    @IBOutlet var trackPicture: UIImageView!
    @IBOutlet var likePicture: UIImageView!
    @IBOutlet var dislikePicture: UIImageView!

    @IBOutlet var trackTitle: UILabel!
    @IBOutlet var trackArtist: UILabel!
    @IBOutlet var addedBy: UILabel!
    @IBOutlet var addedAt: UILabel!
    @IBOutlet var numberLikes: UILabel!
    @IBOutlet var numberDislikes: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
