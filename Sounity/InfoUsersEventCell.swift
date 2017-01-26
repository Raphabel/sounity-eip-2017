//
//  InfoUsersEventCell.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 01/01/2017.
//  Copyright © 2017 Degraeve Raphaël. All rights reserved.
//

import UIKit
class InfoUsersEventCell: UICollectionViewCell {
    
    var user: UserBasicInfo! {
        didSet {
            self.updateUI()
        }
    }
    
    @IBOutlet var picture: UIImageView!
    @IBOutlet var labelStatus: UIView!
    @IBOutlet var status: UILabel!
    @IBOutlet var nickname: UILabel!
    
    
    func updateUI() {
        backgroundView?.backgroundColor = UIColor.white
        
        nickname.text = user.nickname
        if (user.nickname == "sounity") {
            self.picture.image = UIImage(named: "defaultCoverIPV")
            MakeElementRounded().makeElementRounded(self.picture, newSize: self.picture.frame.width)
        } else {
            picture.load.request(with: user.picture, onCompletion: { image, error, operation in
                if (self.picture.image?.size == nil) {
                    self.picture.image = UIImage(named: "emptyPicture")
                }
                MakeElementRounded().makeElementRounded(self.picture, newSize: self.picture.frame.width)
            })
        }
        
        if (user.adminMode) {
            if (user.owner) {
                labelStatus.backgroundColor = ColorSounity.orangeSounity
                status.text = "You are the owner"
            } else if (user.admin) {
                labelStatus.backgroundColor = UIColor(red: CGFloat(0xE6)/255 ,green: CGFloat(0x7E)/255 ,blue: CGFloat(0x22)/255 ,alpha: 0.5)
                status.text = "Is admin"
            } else {
                labelStatus.backgroundColor = UIColor.lightGray
                status.text = "Is not admin"
            }
        } else {
            if (user.banned) {
                labelStatus.backgroundColor = UIColor(red: CGFloat(0xF4)/255 ,green: CGFloat(0x43)/255 ,blue: CGFloat(0x36)/255 ,alpha: 1)
                 status.text = "Is banned"
            } else if (!user.banned && user.participating) {
                labelStatus.backgroundColor = UIColor(red: CGFloat(0xE6)/255 ,green: CGFloat(0x7E)/255 ,blue: CGFloat(0x22)/255 ,alpha: 0.5)
                 status.text = "Is participating"
            } else {
                labelStatus.backgroundColor = UIColor.lightGray
                 status.text = "Is not participating"
            }
        }
    }
}
