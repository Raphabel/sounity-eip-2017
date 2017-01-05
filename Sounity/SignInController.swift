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

class SignInController: UIViewController {
    
    // MARK: StoryBoard UIElements
    @IBOutlet weak var UserName: UITextField!
    @IBOutlet weak var Password: UITextField!
    
    // MARK: Variables
    var dataObject: [String: AnyObject]!
    var user = UserConnect();
    
    // MARK: Override functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserName.delegate = self
        Password.delegate = self
        
        UserName.autocorrectionType = .no
        Password.autocorrectionType = .no
        
        NotificationCenter.default.addObserver(self, selector: #selector(SignInController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SignInController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if (user.checkUserConnected() && self.isViewLoaded) {
            DispatchQueue.main.async(execute: { () -> Void in
                let api = SounityAPI()
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
                            } else {
                                let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Search", bundle: nil)
                                let vc = eventStoryBoard.instantiateViewController(withIdentifier: "HomeViewID") as! HomeController
                                self.present(vc, animated: true, completion: nil)
                            }
                        }
                }
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

// MARK: Setup of the keyboard
extension SignInController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        switch textField
        {
        case UserName:
            Password.becomeFirstResponder()
            break
        default:
            textField.resignFirstResponder()
        }
        return true
    }
    
    func keyboardWillShow(notification: NSNotification) {
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardSize.height
            }
        }
    }
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
