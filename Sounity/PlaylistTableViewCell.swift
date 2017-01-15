//
//  Playlist.swift
//  Sounity
//
//  Created by Alix FORNIELES on 01/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit
import SwiftMoment

class PlaylistTableViewCell: UITableViewCell {
    
    var playlist: Playlist! {
        didSet {
            self.updateUI()
        }
    }
    
    // MARK: Properties
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var descriptionPlaylist: UILabel!
    @IBOutlet weak var picturePlaylist: UIImageView!
    
    func updateUI() {
        nameLabel.text = playlist.name
        descriptionPlaylist.text = playlist.desc
        date.text = moment(playlist.create_date)?.format("YYYY-MM-dd HH:mm")
        
        picturePlaylist.load.request(with: playlist.picture, onCompletion: { image, error, operation in
            if (self.picturePlaylist.image?.size == nil) {
                self.picturePlaylist.image = UIImage(named: "unknownCoverMusic")
            }
            MakeElementRounded().makeElementRounded(self.picturePlaylist, newSize: self.picturePlaylist.frame.width)
        })
    }
}
