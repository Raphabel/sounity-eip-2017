//
//  PlaylistMusicEventTableViewCell.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 18/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation
import UIKit
import SwiftMoment

class PlaylistMusicEventTableViewCell: UITableViewCell {
    
    var music: MusicPlaylistEvent! {
        didSet {
            self.updateUI()
        }
    }
    
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
    
    func updateUI() {
        trackArtist.text = music.artist
        trackTitle.text = music.title
        addedBy.text = music.addedBy
        addedAt.text = moment(music.addedAt)?.format("YYYY-MM-dd, EEE HH:mm")
        
        likePicture.isUserInteractionEnabled = true
        likePicture.image = UIImage(named: "musicNotLike")!
        likePicture.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(PlaylistEventController.likeSongInPlaylistEvent)))
        
        dislikePicture.isUserInteractionEnabled = true
        dislikePicture.image = UIImage(named: "musicNotDislike")!
        dislikePicture.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(PlaylistEventController.dislikeSongInPlaylistEvent)))
        if (music.liked) {
            likePicture.image = UIImage(named: "musicLiked")!
            likePicture.isUserInteractionEnabled = false
        }
        if (music.disliked) {
            dislikePicture.image = UIImage(named: "musicDisliked")!
            dislikePicture.isUserInteractionEnabled = false
        }
        
        numberDislikes.text = String(music.dislike)
        numberLikes.text = String(music.like)
        
        trackPicture.isUserInteractionEnabled = true
        if (music.cover != ""  && Reachability.isConnectedToNetwork() == true) {
            trackPicture.imageFromServerURL(urlString: music.cover)
            MakeElementRounded().makeElementRounded(trackPicture, newSize: trackPicture.frame.width)
        }

    }
}
