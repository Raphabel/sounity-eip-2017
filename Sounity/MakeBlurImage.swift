//
//  MakeBlurImage.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 07/07/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation
import UIKit

class MakeBlurImage {
    func makeImageBlurry(_ imageView : UIImageView){
        //only apply the blur if the user hasn't disabled transparency effects
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = imageView.bounds
            blurEffectView.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
            imageView.addSubview(blurEffectView)
        }
    }
}
