//
//  ViewController.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 14/07/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit
import GuillotineMenu
import AVFoundation
import Alamofire
import SwiftyJSON

class UserHomeViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDelegate {
    
    // MARK: StoryBoard UIElements
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var nickname: UILabel!
    @IBOutlet weak var tableView: UIView!
    @IBOutlet weak var followers: UILabel!
    @IBOutlet weak var descriptionUser: UILabel!
    @IBOutlet var PView: UIView!
    
    // MARK: Infos user connected
    var user = UserConnect()
    
    // MARK: API connection
    var api = SounityAPI()
    
    // MARK: Guillotine menu variable
    fileprivate lazy var presentationAnimator = GuillotineTransitionAnimation()
    
    // MARK: Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setUpHeaderProfil()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        UserGetInfo()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if  segue.identifier == "CheckMyTrophies" {
            let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Profile", bundle: nil)
            let vc = eventStoryBoard.instantiateViewController(withIdentifier: "ProfileTrophiesID") as! TrophiesTableViewController
            vc.userId = self.user.id
            let navController = UINavigationController.init(rootViewController: vc)
            self.present(navController, animated: true, completion: nil)
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

// MARK: Initialisation functions
extension UserHomeViewController {
    /// Get info of the current user
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
                        self.nickname.text = jsonResponse["nickname"].stringValue
                        self.descriptionUser.text = jsonResponse["description"].stringValue
                        
                        if self.user.picture == "" {
                            self.imageView.image = UIImage(named: "UnknownUserCover")!
                        }
                        else if (Reachability.isConnectedToNetwork() == true) {
                            self.imageView.imageFromServerURL(urlString: self.user.picture)
                        }
                    }
                }
        }
    }
    
    /// Setup profil header with user info
    func setUpHeaderProfil () {
        self.PView.backgroundColor = UIColor(patternImage: UIImage(named:"party")!)
        
        self.imageView.layer.borderWidth = 3.0
        self.imageView.layer.borderColor = UIColor.white.cgColor
        self.imageView.layer.masksToBounds = true
        _ = self.putShadowOnView(self.imageView, shadowColor: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), radius: 10, offset: CGSize(width: 0, height: 0), opacity: 1)
        
        if self.user.picture == "" {
            self.imageView.image = UIImage(named: "UnknownUserCover")!
        } else if (Reachability.isConnectedToNetwork() == true) {
            self.imageView.load.request(with: self.user.picture, onCompletion: { image, error, operation in
                if (self.imageView.image?.size == nil) {
                    self.imageView.image = UIImage(named: "emptyPicture")
                }
                MakeElementRounded().makeElementRounded(self.imageView, newSize: self.imageView.frame.width)
            })
        }
    }
}

// MARK: Navagations functions
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
