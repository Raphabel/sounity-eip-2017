//
//  HomeController.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 18/07/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit
import GuillotineMenu
import PageMenu

class HomeController: UIViewController {
    
    // MARK: UIElements variables
    @IBOutlet var barButton: UIButton!
    @IBOutlet var swiftPagesView: CAPSPageMenu!
    
    //MARK: Guillotine menu
    fileprivate lazy var presentationAnimator = GuillotineTransitionAnimation()
    
    //MARK: Infos user connected
    var user: UserConnect?
    
    // MARK: Override functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presentationAnimator.animationDuration = 0.4
        initSwiftPages()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.user = UserConnect()
        
        if (!user!.checkUserConnected() && self.isViewLoaded) {
            DispatchQueue.main.async(execute: { () -> Void in
                let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Authentication", bundle: nil)
                let vc = eventStoryBoard.instantiateViewController(withIdentifier: "LoginSignUpViewID") as! LoginSignUpController
                self.present(vc, animated: true, completion: nil)
            })
        }
        
        if (Reachability.isConnectedToNetwork() == false) {
            let alert = DisplayAlert(title: "No internet", message: "Please find an internet connection")
            alert.openAlertError()
            return
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

//MARK: Swift pages function
extension HomeController {
    func initSwiftPages() {
        automaticallyAdjustsScrollViewInsets = false
        
        var controllersArray : [UIViewController] = []
        let storyboard = UIStoryboard(name: "Search", bundle: nil)
        let eventsController = storyboard.instantiateViewController(withIdentifier: "EventSearchView")
        let musicsController = storyboard.instantiateViewController(withIdentifier: "MusicSearchView")
        let usersController = storyboard.instantiateViewController(withIdentifier: "UserSearchView")
        
        eventsController.title = "Events"
        musicsController.title = "Musics"
        usersController.title = "Users"
        
        controllersArray.append(eventsController)
        controllersArray.append(musicsController)
        controllersArray.append(usersController)
        
        let parameters: [CAPSPageMenuOption] = [
            .menuItemSeparatorWidth(4.3),
            .useMenuLikeSegmentedControl(true),
            .menuItemSeparatorPercentageHeight(0.1),
            .scrollMenuBackgroundColor(ColorSounity.swfitPagesBackgroundColor),
            .viewBackgroundColor(ColorSounity.swfitPagesBackgroundColor),
            .selectionIndicatorColor(ColorSounity.orangeSounity),
            .addBottomMenuHairline(false),
            .unselectedMenuItemLabelColor(UIColor.white),
            .menuHeight(50.0),
            .menuItemFont(UIFont(name: "HelveticaNeue", size: 15.0)!),
            .selectionIndicatorHeight(0.0),
            .menuItemWidthBasedOnTitleTextWidth(true),
            .selectedMenuItemLabelColor(ColorSounity.orangeSounity)
        ]
        
        swiftPagesView = CAPSPageMenu(viewControllers: controllersArray, frame: CGRect(x: 0.0, y: 42.0, width: self.view.frame.width, height: self.view.frame.height), pageMenuOptions: parameters)
        swiftPagesView.viewBackgroundColor = ColorSounity.swfitPagesBackgroundColor
        swiftPagesView.enableHorizontalBounce = true
        
        self.view.addSubview(swiftPagesView!.view)
    }

}

//MARK: Guillotine Action button
extension HomeController {
    @IBAction func showMenuAction(_ sender: UIButton) {
        let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Menu", bundle: nil)
        let menuVC = eventStoryBoard.instantiateViewController(withIdentifier: "MenuViewID")
        menuVC.modalPresentationStyle = .custom
        menuVC.transitioningDelegate = self
        if menuVC is GuillotineAnimationDelegate {
            presentationAnimator.animationDelegate = menuVC as? GuillotineAnimationDelegate
        }
        presentationAnimator.supportView = self.navigationController?.navigationBar
        presentationAnimator.presentButton = sender
        //presentationAnimator.duration = 0.3
        self.present(menuVC, animated: true, completion: nil)
    }

}

//MARK: Hide status bar
extension HomeController {
    override var prefersStatusBarHidden: Bool {
        return false
    }
}

//MARK: Transitioning delegate function
extension HomeController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentationAnimator.mode = .presentation
        return presentationAnimator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentationAnimator.mode = .dismissal
        return presentationAnimator
    }
}
