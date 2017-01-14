//
//  PSTVCell.swift
//  Sounity
//
//  Created by Alix FORNIELES on 14/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit

class MusicsInPlaylistCell: UITableViewCell {
    
    var music: Music! {
        didSet {
            self.updateUI()
        }
    }
    
    @IBOutlet weak var titleMusic: UILabel!
    @IBOutlet weak var artist: UILabel!
    @IBOutlet weak var touchCell: UIView!
    @IBOutlet var playedMusicBtn: UIImageView!
    @IBOutlet var cover: UIImageView!
    @IBOutlet var duration: UILabel!
    @IBOutlet var playMusicBtn: UIImageView!
    
    func updateUI() {
        titleMusic.text = music.title
        artist.text = music.artist
        playMusicBtn.isHidden = false
        playedMusicBtn.isHidden = true
        if (music.played) {
            playMusicBtn.isHidden = true
            playedMusicBtn.isHidden = false
        }
        
        if (music.cover != ""  && Reachability.isConnectedToNetwork() == true) {
            cover.imageFromServerURL(urlString: music.cover)
            MakeElementRounded().makeElementRounded(cover, newSize: cover.frame.width)
        }
        let totalDuration = Int(music.duration)
        let min = totalDuration / 60
        let sec = totalDuration % 60
        duration.text = NSString(format: "%i:%02i",min,sec ) as String
    }
}
