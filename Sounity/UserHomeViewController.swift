//
//  ViewController.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 14/07/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit
import InteractivePlayerView
import GuillotineMenu
import AVFoundation
import Alamofire
import SwiftyJSON

class UserHomeViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDelegate {
    
    // MARK: StoryBoard UIElements
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nickname: UILabel!
    @IBOutlet weak var tableView: UIView!
    @IBOutlet weak var followers: UILabel!
    @IBOutlet weak var descriptionUser: UILabel!
    
    // MARK: Infos user connected
    var user = UserConnect()
    
    // MARK: API connection
    var api = SounityAPI()
    
    // MARK: Guillotine menu variable
    fileprivate lazy var presentationAnimator = GuillotineTransitionAnimation()
    
    // MARK: Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.UserGetInfo()
        self.setUpHeaderProfil()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UserGetInfo()
        
        if user.picture == "" {
            self.imageView.image = UIImage(named: "UnknownUserCover")!
        }
        else if (Reachability.isConnectedToNetwork() == true) {
            self.imageView.imageFromServerURL(urlString: self.user.picture)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if (!user.checkUserConnected() && self.isViewLoaded) {
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
        // Dispose of any resources that can be recreated.
    }
}

// MARK: Get Info users
extension UserHomeViewController {
    func UserGetInfo() {
        let url = api.getRoute(SounityAPI.ROUTES.CREATE_USER) + "/" + "\(user.id)"
        Alamofire.request(url, method: .get)
            .validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! == 400) {
                        self.dismiss(animated: true, completion: nil)
                        let alert = DisplayAlert(title: "My profile", message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        self.user.setHisFirstName(jsonResponse["first_name"].stringValue)
                        self.user.setHisLastName(jsonResponse["last_name"].stringValue)
                        self.user.setHisBirthday(jsonResponse["birth_date"].stringValue)
                        self.user.setHisDescription(jsonResponse["description"].stringValue)
                        
                        self.nickname.text = self.user.username
                        self.descriptionUser.text = self.user.descriptionUser
                    }
                }
        }
    }
}

// MARK: Nivagations functions
extension UserHomeViewController {
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
        presentationAnimator.animationDuration = 0.3
        self.present(menuVC, animated: true, completion: nil)
    }
}

// MARK: Initialisation functions 
extension UserHomeViewController {
    func setUpHeaderProfil () {
        self.imageView.layer.cornerRadius = imageView.frame.width/2
        self.imageView.layer.masksToBounds = true
        _ = self.putShadowOnView(imageView, shadowColor: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), radius: 10, offset: CGSize(width: 0, height: 0), opacity: 1)
        
        if user.picture == "" {
            self.imageView.image = UIImage(named: "UnknownUserCover")!
        }
        else if (Reachability.isConnectedToNetwork() == true) {
            self.imageView.imageFromServerURL(urlString: self.user.picture)
        }
    }
}

// MARK: Design functions
extension UserHomeViewController {
    func putShadowOnView(_ viewToWorkUpon:UIView, shadowColor:UIColor, radius:CGFloat, offset:CGSize, opacity:Float)-> UIView{
        var shadowFrame = CGRect.zero // Modify this if needed
        shadowFrame.size.width = viewToWorkUpon.frame.width
        shadowFrame.size.height = viewToWorkUpon.frame.height
        shadowFrame.origin.x = 0
        shadowFrame.origin.y = 0
        
        let shadow = UIView(frame: shadowFrame)//[[UIView alloc] initWithFrame:shadowFrame];
        shadow.isUserInteractionEnabled = true; // Modify this if needed
        shadow.layer.shadowColor = shadowColor.cgColor
        shadow.layer.shadowOffset = offset
        shadow.layer.shadowRadius = 50
        shadow.layer.masksToBounds = false
        shadow.clipsToBounds = false
        shadow.layer.shadowOpacity = opacity
        viewToWorkUpon.superview?.insertSubview(shadow, belowSubview: viewToWorkUpon)
        
        shadow.addSubview(viewToWorkUpon)
        return shadow
    }
}

// MARK: Transition delegate functions
extension UserHomeViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentationAnimator.mode = .presentation
        return presentationAnimator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentationAnimator.mode = .dismissal
        return presentationAnimator
    }
}

// MARK: Hide status bar
extension UserHomeViewController {
    override var prefersStatusBarHidden : Bool {
        return false
    }
}
