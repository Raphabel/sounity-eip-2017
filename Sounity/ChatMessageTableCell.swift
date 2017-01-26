//
//  ChatMessageTableCell.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 17/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit
import SwiftMoment

class ChatMessageTableCell: UITableViewCell {
    
    var message: MessageChat! {
        didSet {
            self.updateUI()
        }
    }
    
    // MARK: Info user connected
    var user = UserConnect()
    
    @IBOutlet var viewOtherUser: UIView!
    @IBOutlet var pictureOtherUser: UIImageView!
    @IBOutlet var timeOther: UILabel!
    @IBOutlet var nicknameOther: UILabel!
    @IBOutlet var messageOther: UILabel!
    
    
    @IBOutlet var viewOwnUser: UIView!
    @IBOutlet var pictureOwnUser: UIImageView!
    @IBOutlet var timeOwn: UILabel!
    @IBOutlet var nicknameOwn: UILabel!
    @IBOutlet var messageOwn: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func updateUI() {
        if (user.username == message.nickname) {
            viewOwnUser.isHidden = false
            viewOtherUser.isHidden = true
            viewOwnUser.layer.cornerRadius = 6
            nicknameOwn.text = "You"
            timeOwn.text = moment(message.time)?.format("EEE, HH:mm")
            messageOwn.text = message.message
            pictureOwnUser.image = UIImage(named: "UnknownUserCover")
            
            // Useless memory request
            /*if (message.picture != "" && Reachability.isConnectedToNetwork() == true) {
                pictureOwnUser.load.request(with: message.picture)
                MakeElementRounded().makeElementRounded(pictureOwnUser, newSize: pictureOwnUser.frame.width)
            }*/
        } else {
            viewOtherUser.isHidden = false
            viewOwnUser.isHidden = true
            viewOtherUser.layer.cornerRadius = 6
            nicknameOther.text = user.username == message.nickname ? "You" : message.nickname
            timeOther.text = moment(message.time)?.format("EEE, HH:mm")
            messageOther.text = message.message
            pictureOtherUser.image = UIImage(named: "UnknownUserCover")
            
            // Useless memory request
            /*if (message.picture != "" && Reachability.isConnectedToNetwork() == true) {
                pictureOtherUser.load.request(with: message.picture)
                MakeElementRounded().makeElementRounded(pictureOtherUser, newSize: pictureOtherUser.frame.width)
            }*/
        }

    }
}
