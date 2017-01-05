//
//  DisplayAlert.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 10/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation
import SCLAlertView
import MapKit

class DisplayAlert {
    var title: String
    var message: String
    
    init(title: String, message: String) {
        self.title = title
        self.message = message
    }
    
    init(message: String) {
        self.title = ""
        self.message = message
    }
    
    func getPopAlert() -> UIAlertController {
        let button = "OK"
        
        let alert = UIAlertController(title : self.title, message: self.message, preferredStyle: UIAlertControllerStyle.actionSheet)
        let buttonAlert = UIAlertAction(title : button, style: UIAlertActionStyle.cancel , handler: nil)
        alert.addAction(buttonAlert)
        
        return alert
    }
    
    func openAlertSuccess() {
        let alertAppearance = SCLAlertView.SCLAppearance(
            showCircularIcon: true,
            kCircleIconHeight: 30,
            kCircleHeight: 55,
            showCloseButton: true,
            shouldAutoDismiss: false,
            hideWhenBackgroundViewIsTapped: true
        )
        let alert = SCLAlertView(appearance: alertAppearance)
        _ = alert.showCustom(self.title, subTitle: self.message, color: ColorSounity.orangeSounity, icon: UIImage(named: "iconSounityWhite")!, closeButtonTitle: "OK")
    }
    
    func openAlertError() {
        let alertAppearance = SCLAlertView.SCLAppearance(
            showCircularIcon: true,
            kCircleIconHeight: 30,
            kCircleHeight: 55,
            showCloseButton: true,
            shouldAutoDismiss: false,
            hideWhenBackgroundViewIsTapped: true
        )
        let alert = SCLAlertView(appearance: alertAppearance)
        let colorError = UIColor(red: CGFloat(0xF4)/255 ,green: CGFloat(0x43)/255 ,blue: CGFloat(0x36)/255 ,alpha: 1)
        _ = alert.showCustom(self.title, subTitle: self.message, color: colorError, icon: UIImage(named: "iconSounityWhite")!, closeButtonTitle: "OK")
    }
    
    func openAlertConfirmationWithCallbackNoOption(_ callback: @escaping () -> ()) {
        let alertAppearance = SCLAlertView.SCLAppearance(
            showCircularIcon: true,
            kCircleIconHeight: 30,
            kCircleHeight: 55,
            showCloseButton: false,
            shouldAutoDismiss: false,
            hideWhenBackgroundViewIsTapped: true
        )
        let alert = SCLAlertView(appearance: alertAppearance)
        alert.addButton("Ok") {
            callback()
            alert.hideView()
        }
        let colorError = UIColor(red: CGFloat(0xF4)/255 ,green: CGFloat(0x43)/255 ,blue: CGFloat(0x36)/255 ,alpha: 1)
        _ = alert.showCustom(self.title, subTitle: self.message, color: colorError, icon: UIImage(named: "iconSounityWhite")!)
    }
    
    func openAlertConfirmationWithCallback(_ callback: @escaping () -> ()) {
        let alertAppearance = SCLAlertView.SCLAppearance(
            showCircularIcon: true,
            kCircleIconHeight: 30,
            kCircleHeight: 55,
            showCloseButton: true,
            shouldAutoDismiss: false,
            hideWhenBackgroundViewIsTapped: true
        )
        let alert = SCLAlertView(appearance: alertAppearance)
        alert.addButton("Yes") {
            callback()
            alert.hideView()
        }
        _ = alert.showCustom(self.title, subTitle: self.message, color: ColorSounity.navigationBarColor, icon: UIImage(named: "iconSounityWhite")!, closeButtonTitle: "No")
    }
    
    func openAlertConfirmationWithCallbackAndParameterIndexPath(_ callback: @escaping (IndexPath) -> (), indexPath: IndexPath) {
        let alertAppearance = SCLAlertView.SCLAppearance(
            showCircularIcon: true,
            kCircleIconHeight: 30,
            kCircleHeight: 55,
            showCloseButton: true,
            shouldAutoDismiss: false,
            hideWhenBackgroundViewIsTapped: true
        )
        let alert = SCLAlertView(appearance: alertAppearance)
        alert.addButton("Yes") {
            callback(indexPath)
            alert.hideView()
        }
        _ = alert.showCustom(self.title, subTitle: self.message, color: ColorSounity.navigationBarColor, icon: UIImage(named: "iconSounityWhite")!, closeButtonTitle: "No")
    }
    
    func openAlertConfirmationWithCallbackAndParameterForMapKit(_ callback: @escaping (MKMapView, MKAnnotationView) -> (), view: MKMapView, annotation: MKAnnotationView) {
        let alertAppearance = SCLAlertView.SCLAppearance(
            showCircularIcon: true,
            kCircleIconHeight: 30,
            kCircleHeight: 55,
            showCloseButton: false,
            shouldAutoDismiss: false,
            hideWhenBackgroundViewIsTapped: true
        )
        let alert = SCLAlertView(appearance: alertAppearance)
        alert.addButton("Yes") {
            callback(view, annotation)
            alert.hideView()
        }
        _ = alert.showCustom(self.title, subTitle: self.message, color: ColorSounity.navigationBarColor, icon: UIImage(named: "iconSounityWhite")!)
    }
}
