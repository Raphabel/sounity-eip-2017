//
//  PSTVCell.swift
//  Sounity
//
//  Created by Alix FORNIELES on 14/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit

class MusicsInPlaylistCell: UITableViewCell {
    
    @IBOutlet weak var titleMusic: UILabel!
    @IBOutlet weak var artist: UILabel!
    @IBOutlet weak var touchCell: UIView!
    @IBOutlet var playedMusicBtn: UIImageView!
    @IBOutlet var cover: UIImageView!
    @IBOutlet var duration: UILabel!
    @IBOutlet var playMusicBtn: UIImageView!
}
