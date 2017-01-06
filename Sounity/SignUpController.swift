//
//  SignUpController.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 16/07/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class SignUpController: UIViewController {
    
    // MARK: UIElements variables
    @IBOutlet weak var PasswordCheck: UITextField!
    @IBOutlet weak var UserName: UITextField!
    @IBOutlet weak var Password: UITextField!
    @IBOutlet weak var ButtonCreateAccount: HexagonalButton!
    @IBOutlet weak var Email: UITextField!
    @IBOutlet weak var TextFieldPicker: UITextField!
    
    // MARK: Picker view variables
    var pickOption = Array<Array<String>>()
    var pickOptionIDs = Array<Array<Int>>()
    var pickerView = UIPickerView()
    var dataObject: [String: AnyObject]!
    
    // MARK: Infos user connected
    var user = UserConnect();
    
    // MARK: API Connection
    var api = SounityAPI()
    
    // MARK: Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserName.delegate = self
        Email.delegate = self
        Password.delegate = self
        PasswordCheck.delegate = self
        
        UserName.autocorrectionType = .no
        Email.autocorrectionType = .no
        Password.autocorrectionType = .no
        PasswordCheck.autocorrectionType = .no

        NotificationCenter.default.addObserver(self, selector: #selector(SignUpController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SignUpController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        //Set pickOptions
        getCountriesAndLanguages();
        
        //Image Modification
        self.ButtonCreateAccount.setImage(UIImage(named: "ButtonCreateAccount"), for: UIControlState())
        self.TextFieldPicker.background = UIImage(named: "TextFieldLanguage")
        self.Email.background = UIImage(named: "TextFieldEmail")
        self.initPickerTextField()
        
        //PlaceHolder Modification
        self.TextFieldPicker.attributedPlaceholder = NSAttributedString(string:"Country & Language", attributes:[NSForegroundColorAttributeName: UIColor.gray])
        self.PasswordCheck.attributedPlaceholder = NSAttributedString(string:"Password Check", attributes:[NSForegroundColorAttributeName: UIColor.gray])
        self.Email.attributedPlaceholder = NSAttributedString(string:"Email", attributes:[NSForegroundColorAttributeName: UIColor.gray])
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

// MARK: Setup of the keyboard
extension SignUpController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        switch textField
        {
        case UserName:
            Email.becomeFirstResponder()
            break
        case Email:
            Password.becomeFirstResponder()
            break
        case Password:
            PasswordCheck.becomeFirstResponder()
            break
        case PasswordCheck:
            PasswordCheck.resignFirstResponder()
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

// MARK: GET Countries & Languges possibilities
extension SignUpController {
    
    func getCountriesAndLanguages() {
        Alamofire.request(api.getRoute(SounityAPI.ROUTES.COUNTRIES), method: .get)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseJSON
            {
                response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    self.pickOption.append(Array(repeating:String(), count:jsonResponse.count))
                    self.pickOptionIDs.append(Array(repeating:Int(), count:jsonResponse.count))
                    for (_,subJson):(String, JSON) in jsonResponse {
                        self.pickOptionIDs[0].append(subJson["id"].intValue);
                        self.pickOption[0].append(subJson["name"].stringValue)
                    }
                }
                
                Alamofire.request(self.api.getRoute(SounityAPI.ROUTES.LANGUAGES), method: .get)
                    .validate(statusCode: 200..<300)
                    .validate(contentType: ["application/json"])
                    .responseJSON
                    {
                        response in
                        if let apiResponse = response.result.value {
                            let jsonResponse = JSON(apiResponse)
                            self.pickOption.append(Array(repeating:String(), count:jsonResponse.count))
                            self.pickOptionIDs.append(Array(repeating:Int(), count:jsonResponse.count))
                            for (_,subJson):(String, JSON) in jsonResponse {
                                self.pickOptionIDs[1].append(subJson["id"].intValue);
                                self.pickOption[1].append(subJson["name"].stringValue)
                            }
                        }
                }
        }
    }
}

// MARK: Create new account
extension SignUpController {
    @IBAction func ButtonOnClick(_ sender: AnyObject) {
        
        if (Reachability.isConnectedToNetwork() == false) {
            let alert = DisplayAlert(title: "No internet", message: "Please find an internet connection")
            alert.openAlertError()
            return
        }
        
        let parameters: Parameters = [
            "nickname": UserName.text! ,
            "email": Email.text!,
            "password": Password.text!,
            "password_check": PasswordCheck.text!,
            "id_country": String(self.pickOptionIDs[0][self.pickerView.selectedRow(inComponent: 0)]),
            "id_language": String(self.pickOptionIDs[1][self.pickerView.selectedRow(inComponent: 1)]),
            ]
        Alamofire.request(api.getRoute(SounityAPI.ROUTES.CREATE_USER), method: .post, parameters: parameters)
            .validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON
            {
                response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    
                    if ((response.response?.statusCode)! == 400) {
                        let alert = DisplayAlert(title: "Create Account", message: jsonResponse["message"].stringValue)
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

// MARK: Picker view functions
extension SignUpController: UIPickerViewDataSource, UIPickerViewDelegate {
    func initPickerTextField()
    {
        pickerView.delegate = self
        TextFieldPicker.inputView = pickerView
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: self.view.frame.size.height/6, width: self.view.frame.size.width, height: 40.0))
        toolBar.layer.position = CGPoint(x: self.view.frame.size.width/2, y: self.view.frame.size.height-20.0)
        toolBar.barStyle = UIBarStyle.blackTranslucent
        toolBar.tintColor = UIColor.white
        toolBar.backgroundColor = UIColor.black
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(SignUpController.donePressed(_:)))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width / 3, height: self.view.frame.size.height))
        
        label.font = UIFont(name: "Helvetica", size: 12)
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.white
        label.text = "Country & Language"
        label.textAlignment = NSTextAlignment.center
        
        let textBtn = UIBarButtonItem(customView: label)
        toolBar.setItems([flexSpace,textBtn,flexSpace,doneButton], animated: true)
        TextFieldPicker.inputAccessoryView = toolBar
    }
    
    func donePressed(_ sender: UIBarButtonItem) {
        TextFieldPicker.resignFirstResponder()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return pickOption.count
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickOption[component].count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickOption[component][row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let color = pickOption[0][pickerView.selectedRow(inComponent: 0)]
        let model = pickOption[1][pickerView.selectedRow(inComponent: 1)]
        TextFieldPicker.text = color + " | " + model
    }
}
