//
//  HexagonalTextField.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 16/07/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation
import UIKit

open class HexagonalTextField : UITextField {
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // Begining of the modification
        self.textColor = UIColor.white
        self.backgroundColor = UIColor.clear
        self.borderStyle = UITextBorderStyle.none
        
        // Define Text Padding
        let paddingViewLeft = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: self.frame.height))
        let paddingViewRight = UIView(frame: CGRect(x: 0, y: 0, width: 25, height: self.frame.height))
        self.leftView = paddingViewLeft
        self.rightView = paddingViewRight
        self.leftViewMode = UITextFieldViewMode.always
        self.rightViewMode = UITextFieldViewMode.always
        
        self.background = UIImage(named: "Hexagon")
    }
}
