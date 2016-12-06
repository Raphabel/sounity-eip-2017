//
//  ColorSounity.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 07/07/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation
import UIKit

struct ColorSounity {
    
    // Color Sounity
    
    static var orangeSounity = UIColor(red: CGFloat(0xE6)/255 ,green: CGFloat(0x7E)/255 ,blue: CGFloat(0x22)/255 ,alpha: 1)
    static var navigationBarColor = UIColor(red: CGFloat(0x41)/255 ,green: CGFloat(0x3E)/255 ,blue: CGFloat(0x4F)/255 ,alpha: 0.7)
    static var navigationBarTintColor = UIColor(red: CGFloat(0x00)/255 ,green: CGFloat(0x00)/255 ,blue: CGFloat(0x00)/255 ,alpha: 1)
    
    // Home controller swift pages
    static var swfitPagesBackgroundColor = UIColor(red: CGFloat(0x41)/255 ,green: CGFloat(0x3E)/255 ,blue: CGFloat(0x4F)/255 ,alpha: 0.9)
    static var swfitPagesBackgroundColorAnimated = UIColor(red: CGFloat(0xFF)/255 ,green: CGFloat(0xFF)/255 ,blue: CGFloat(0xFF)/255 ,alpha: 1)
    
    static func themeOrange() {
        orangeSounity = UIColor(red: CGFloat(0xE6)/255 ,green: CGFloat(0x7E)/255 ,blue: CGFloat(0x22)/255 ,alpha: 1)
        navigationBarColor = UIColor(red: CGFloat(0x41)/255 ,green: CGFloat(0x3E)/255 ,blue: CGFloat(0x4F)/255 ,alpha: 0.7)
        navigationBarTintColor = UIColor(red: CGFloat(0x00)/255 ,green: CGFloat(0x00)/255 ,blue: CGFloat(0x00)/255 ,alpha: 1)
        swfitPagesBackgroundColor = UIColor(red: CGFloat(0x41)/255 ,green: CGFloat(0x3E)/255 ,blue: CGFloat(0x4F)/255 ,alpha: 0.9)
        swfitPagesBackgroundColorAnimated = UIColor(red: CGFloat(0xFF)/255 ,green: CGFloat(0xFF)/255 ,blue: CGFloat(0xFF)/255 ,alpha: 1)
    }
    
    static let availableThemes = ["Dark Orange"]
    static func loadTheme(){
        let defaults = UserDefaults.standard
        if let name = defaults.string(forKey: "Theme") {
            if name == "Dark Orange" { themeOrange() }
        } else {
            defaults.set("Dark Orange", forKey: "Theme")
            themeOrange()
        }
    }
}
