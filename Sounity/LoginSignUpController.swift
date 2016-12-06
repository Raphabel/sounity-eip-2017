//
//  LoginSignUpController.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 16/07/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit
import Foundation

class LoginSignUpController: RGPageViewController, RGPageViewControllerDelegate {
    
    // MARK: TabTitle varibales
    var tabTitles: [String] = []
    var data: [[String: AnyObject]] = []
    
    // MARK: Override functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabTitles = ["Sign In", "Sign Up"]
        let signIn = ["title" : "Sign In"]
        let signUp = ["title" : "Sign Up"]
        data = [signIn as Dictionary<String, AnyObject>, signUp as Dictionary<String, AnyObject>]
        
        self.datasource = self
        self.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var tabbarPosition: RGTabbarPosition {
        get {
            return RGTabbarPosition.top
        }
    }
    
    override var barTintColor : UIColor {
        get {
            return UIColor.clear
        }
    }
}

// MARK: Page View Delegate functions
extension LoginSignUpController: RGPageViewControllerDataSource {
    func numberOfPagesForViewController(_ pageViewController: RGPageViewController) -> Int {
        return data.count
    }
    
    func tabViewForPageAtIndex(_ pageViewController: RGPageViewController, index: Int) -> UIView
    {
        // return a simple label for the tab view
        let title: String = tabTitles[index]
        let label: UILabel = UILabel()
        
        label.text = title
        label.textColor = UIColor.white
        label.sizeToFit()
        return label
    }
    
    func viewControllerForPageAtIndex(_ pageViewController: RGPageViewController, index: Int) -> UIViewController?
    {
        if (data.count == 0) || (index >= data.count) {
            return nil
        }
        
        if (index == 0){
            let eventSignInController = storyboard!.instantiateViewController(withIdentifier: "SignInView") as! SignInController
            eventSignInController.dataObject = data[index]
            return eventSignInController
        } else {
            let eventSignUpController = storyboard!.instantiateViewController(withIdentifier: "SignUpView") as! SignUpController
            eventSignUpController.dataObject = data[index]
            return eventSignUpController
        }
    }
    
    func widthForTabAtIndex(_ index: Int) -> CGFloat
    {
        return self.view.frame.size.width / 2
    }
}

// MARK: Hide Top Bar
extension LoginSignUpController {
    override var prefersStatusBarHidden : Bool {
        return true
    }
}
