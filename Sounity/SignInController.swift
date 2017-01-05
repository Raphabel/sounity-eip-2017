//
//  SignInController.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 16/07/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
//import GoogleSignIn
//import Google

class SignInController: UIViewController/*, GIDSignInUIDelegate, GIDSignInDelegate*/ {
    
    // MARK: StoryBoard UIElements
    @IBOutlet weak var UserName: HexagonalTextFieldWithIcon!
    @IBOutlet weak var Password: HexagonalTextFieldPassword!
    
    // MARK: Variables
    var dataObject: [String: AnyObject]!
    var user = UserConnect();
    
    // MARK: Override functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*var error: NSError?
        GGLContext.sharedInstance().configureWithError(&error)
        
        if error != nil {
            print(error)
            return
        }
        
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        
        let signInButton = GIDSignInButton(frame: CGRectMake(0, 0, 100, 50))
        signInButton.center = view.center
        
        view.addSubview(signInButton)*/
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if (user.checkUserConnected() && self.isViewLoaded) {
            DispatchQueue.main.async(execute: { () -> Void in
                /*let api = SounityAPI()
                let parameters: Parameters = ["token" : self.user.token as String]
                Alamofire.request(api.getRoute(SounityAPI.ROUTES.TOKEN), method: .post, parameters: parameters, headers: nil)
                    .validate(statusCode: 200..<501)
                    .validate(contentType: ["application/json"])
                    .responseJSON { response in
                        if let apiResponse = response.result.value {
                            let jsonResponse = JSON(apiResponse)
                            if ((response.response?.statusCode)! == 400) {
                                let alert = DisplayAlert(title: "Login", message: jsonResponse["message"].stringValue)
                                alert.openAlertError()
                            } else {*/
                                let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Search", bundle: nil)
                                let vc = eventStoryBoard.instantiateViewController(withIdentifier: "HomeViewID") as! HomeController
                                self.present(vc, animated: true, completion: nil)
                            /*}
                        }
                }*/
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    /**
     * Called when the user click on the view (outside the UITextField).
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

}

extension SignInController {
    /*func signIn(_ signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError!) {
        if error != nil {
            print(error)
            return
        }
        
        print("email -> \(user.profile.email)")
        print("picture -> \(user.profile.imageURLWithDimension(400))")
        print("firstname -> \(user.profile.name)")
        print("lastname -> \(user.profile.familyName)")
        print("token -> \(user.authentication.accessToken)")
    }*/
}

// MARK: Check if user is logged
extension SignInController {
    func checkUserLog() {
        let tokenUser = UserDefaults.standard.string(forKey: "tokenUser")
        if ((tokenUser) != nil) {
            print("With have a token stored")
        }
    }
}

// MARK: Log user in
extension SignInController {
    @IBAction func OnClick(_ sender: AnyObject) {
        let api = SounityAPI()
        let username = UserName.text!
        let password = Password.text!
        
        if (Reachability.isConnectedToNetwork() == false) {
            let alert = DisplayAlert(title: "No internet", message: "Please find an internet connection")
            alert.openAlertError()
            return
        }
        
        let parameters: Parameters = ["nickname" : username as String, "password" : password as String]
        Alamofire.request(api.getRoute(SounityAPI.ROUTES.LOGIN), method: .post, parameters: parameters, headers: nil)
            .validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! == 400) {
                        let alert = DisplayAlert(title: "Login", message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        self.user.setHisToken(jsonResponse["token"].stringValue);
                        self.user.setHisId(jsonResponse["id"].intValue)
                        self.user.setHisUsername(jsonResponse["nickname"].stringValue);
                        self.user.setHisPicture(jsonResponse["picture"].stringValue);
                        
                        let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Search", bundle: nil)
                        let vc = eventStoryBoard.instantiateViewController(withIdentifier: "HomeViewID") as! HomeController
                        self.present(vc, animated: true, completion: nil)
                    }
                }
        }
    }
}

//MARK: Hide status bar
extension SignInController
{
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
