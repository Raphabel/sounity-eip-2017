//
//  HexagonalTextFieldWithIcon.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 16/07/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation
import UIKit

class HexagonalTextFieldWithIcon : UITextField {
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // Begining of the modification
        self.textColor = UIColor.white
        self.backgroundColor = UIColor.clear
        self.borderStyle = UITextBorderStyle.none
        
        // Define Text Padding
        let paddingViewLeft = UIView(frame: CGRect(x: 0, y: 0, width: 70, height: self.frame.height))
        let paddingViewRight = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: self.frame.height))
        self.leftView = paddingViewLeft
        self.rightView = paddingViewRight
        self.leftViewMode = UITextFieldViewMode.always
        self.rightViewMode = UITextFieldViewMode.always
        
        self.attributedPlaceholder = NSAttributedString(string:"User Name", attributes:[NSForegroundColorAttributeName: UIColor.gray])
        self.background = UIImage(named: "TextFieldUserName")
    }
}
