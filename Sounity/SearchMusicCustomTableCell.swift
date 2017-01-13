//
//  SearchMusicEventCustomCell.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 18/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation
import UIKit

class SearchMusicCustomTableCell: UITableViewCell {
    
    var music: SounityTrackResearch! {
        didSet {
            self.updateUI()
        }
    }
    
    @IBOutlet var trackPicture: UIImageView!
    @IBOutlet var trackTitle: UILabel!
    @IBOutlet var trackArtist: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func updateUI() {
        trackTitle.text = music.title
        trackArtist.text = music.artist
        
        if (music.cover == "") {
            trackPicture.image = UIImage(named: "UnknownMusicCover")!
        }
        else if (Reachability.isConnectedToNetwork() == true) {
            trackPicture.imageFromServerURL(urlString: music.cover)
            MakeElementRounded().makeElementRounded(trackPicture, newSize: trackPicture.frame.width)
        }

    }
}
