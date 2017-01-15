//
//  SounityStartTrophiesTableViewCell.swift
//  Sounity
//
//  Created by Alix FORNIELES on 07/01/2017.
//  Copyright © 2017 Degraeve Raphaël. All rights reserved.
//

import UIKit

class TrophiesTableViewCell: UITableViewCell {

    var trophy: Trophies! {
        didSet {
            self.updateUI()
        }
    }
    
    // MARK: IconsGamification
    var icons = [#imageLiteral(resourceName: "JukeBox"), #imageLiteral(resourceName: "BestDJ"), #imageLiteral(resourceName: "SounityStar"), #imageLiteral(resourceName: "KingOfTheNight"), #imageLiteral(resourceName: "SocialNetworkAddict"), #imageLiteral(resourceName: "PartyAnimal"), #imageLiteral(resourceName: "Rockstar")]
    var iconsDark = [#imageLiteral(resourceName: "JukeBoxDark"), #imageLiteral(resourceName: "BestDJDark"), #imageLiteral(resourceName: "SounityStarDark"), #imageLiteral(resourceName: "KingOfTheNightDark"), #imageLiteral(resourceName: "SocialNetworkAddictDark"), #imageLiteral(resourceName: "PartyAnimalDark"), #imageLiteral(resourceName: "RockstarDark")]
    
    @IBOutlet weak var Name: UILabel!
    @IBOutlet weak var descriptionTrophies: UILabel!
    @IBOutlet weak var levelNumber: UILabel!
    @IBOutlet weak var levelImage: UIImageView!
    @IBOutlet var backgroundCardView: UIView!
    
    @IBOutlet weak var level1: UIImageView!
    @IBOutlet weak var level2: UIImageView!
    @IBOutlet weak var level3: UIImageView!
    @IBOutlet weak var level4: UIImageView!
    @IBOutlet weak var level5: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func updateUI() {
        Name.text = trophy.name
        levelNumber.text = String(trophy.level)
        descriptionTrophies.text = trophy.desc
        
        levelImage.image = trophy.level >= 1 ? icons[(trophy.id - 1)] : iconsDark[(trophy.id - 1)]

        switch trophy.level {
        case 0:
            level1.image = UIImage(named: "levelDark")
            level2.image = UIImage(named: "levelDark")
            level3.image = UIImage(named: "levelDark")
            level4.image = UIImage(named: "levelDark")
            level5.image = UIImage(named: "levelDark")
            break
        case 1:
            level2.image = UIImage(named: "levelDark")
            level3.image = UIImage(named: "levelDark")
            level4.image = UIImage(named: "levelDark")
            level5.image = UIImage(named: "levelDark")
            break
        case 2:
            level3.image = UIImage(named: "levelDark")
            level4.image = UIImage(named: "levelDark")
            level5.image = UIImage(named: "levelDark")
            break
        case 3:
            level4.image = UIImage(named: "levelDark")
            level5.image = UIImage(named: "levelDark")
            break
        case 4:
            level5.image = UIImage(named: "levelDark")
            break
        default: break
        }
        
        backgroundCardView.backgroundColor = UIColor.white
        contentView.backgroundColor = UIColor(red: 120/255 ,green: 118/255 ,blue: 130/255 ,alpha: 1)
        
        backgroundCardView.layer.cornerRadius = 3.0
        backgroundCardView.layer.masksToBounds = false
        
        backgroundCardView.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        
        backgroundCardView.layer.shadowOffset = CGSize(width: 0, height: 0)
        backgroundCardView.layer.shadowOpacity = 0.8
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
