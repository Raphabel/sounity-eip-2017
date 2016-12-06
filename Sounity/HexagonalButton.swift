//
//  HexagonalButton.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 16/07/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation
import UIKit

open class HexagonalButton : UIButton {
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        //self.backgroundColor = UIColor.clearColor()
        let img = UIImage(named: "ConnectButton")
        self.setImage(img, for: UIControlState())
        self.titleLabel?.textColor = UIColor.white
        self.tintColor = UIColor.white
        self.titleLabel?.text = "Login"
        
    }
}
