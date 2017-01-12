//
//  Timeline.swift
//  Sounity
//
//  Created by Alix FORNIELES on 08/12/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit
import SwiftMoment

class TimelineTableViewCell: UICollectionViewCell {

    var feed: newFeed! {
        didSet {
            self.updateUI()
        }
    }
    
    var user = UserConnect()
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var statusTextView: UITextView!
    @IBOutlet weak var statusImageView: UIImageView!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var actionButton: UIButton!
    
    
    func updateUI() {
        self.nameLabel.text = feed.user.nickname
        
        self.dateLabel.text = ((moment(feed.created_date)?.format("YYYY-MM-dd, EEE HH:mm"))!)
        self.dateLabel.textColor = UIColor.rgb(red: 155, green: 161, blue: 161)
        
        self.profileImageView.imageFromServerURL(urlString: feed.user.picture)
        self.profileImageView.contentMode = .scaleAspectFit
        MakeElementRounded().makeElementRounded(self.profileImageView, newSize: self.profileImageView.frame.width)
        
        self.statusTextView.text = feed.message
        self.statusTextView.font = UIFont.systemFont(ofSize: 14)
        
        self.statusImageView.imageFromServerURL(urlString: feed.eventInfo != nil ? (feed.eventInfo?.picture)! : feed.followerInfo != nil ? (feed.followerInfo?.picture)! : feed.user.picture)
        self.statusImageView.layer.masksToBounds = true
        
        self.actionButton.setTitle(feed.eventInfo != nil ? "Consult Event" : feed.followerInfo != nil ? "Consult \(feed.followerInfo?.nickname)'s profile" : feed.user.id != self.user.id ? "Consult \(feed.user.nickname)'s profile" : "Consult your profile", for: UIControlState.normal)
        
        backgroundColor = UIColor.white
    }
}
