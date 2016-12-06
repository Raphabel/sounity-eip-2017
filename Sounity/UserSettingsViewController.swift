//
//  SettingsToChange.swift
//  Sounity
//
//  Created by Alix FORNIELES on 19/07/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit
import Eureka
import Alamofire
import SwiftyJSON
import SwiftMoment

class UserSettingsViewController: FormViewController {
    
    // MARK: API Connection
    var api = SounityAPI()
    
    // MARK: Infos user connected
    var user = UserConnect()
    
    // MARK: Valid Checkname info
    var checkNickname = false
    
    // MARK: Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ImageRow.defaultCellUpdate = { cell, row in
            cell.accessoryView?.layer.cornerRadius = 17
            cell.accessoryView?.frame = CGRect(0, 0, 34, 34)
        }
       
        loadSettingsUser()
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
}

// MARK: Update Info User functions
extension UserSettingsViewController {
    func validate(_ nickname: String) -> Bool {
        if (Reachability.isConnectedToNetwork() == false) {
            let alert = DisplayAlert(title: "No internet", message: "Please find an internet connection")
            alert.openAlertError()
            return false
        }
        
        let headers = [ "Authorization": "Bearer \(user.token)", "Content-Type": "application/x-www-form-urlencoded"]
        let url = api.getRoute(SounityAPI.ROUTES.CHECK_NICKNAME)
        let parameters : Parameters = ["nickname": nickname as AnyObject ]
        
        let semaphore = DispatchSemaphore(value: 1)
        
        let watchdogTime = DispatchTime.now() + DispatchTimeInterval.milliseconds(100)
        if case DispatchTimeoutResult.timedOut = semaphore.wait(timeout: watchdogTime) {
            print("Semaphore blocking app")
        }
        
        Alamofire.request(url, method: .post, parameters: parameters, headers : headers)
            .validate(statusCode: 200..<499)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if ((response.response?.statusCode) == 400) {
                    self.checkNickname = false
                } else {
                    self.checkNickname = true
                }
                semaphore.signal()
        }
        
        return self.checkNickname
    }
    
    @IBAction func showAlert() {
        //var newCoverURL: URL?
        let allFormData = form.values()
        
        let nickname = allFormData["nickname"] as? String
        let firstname = allFormData["firstname"] as? String
        let lastname = allFormData["lastname"] as? String
        let description = allFormData["description"] as? String
        let date = allFormData["birthday"] as? NSDate
        
        
        /*if let rowCover = self.form.rowBy(tag: "picture")! as? ImageRow {
            newCoverURL = rowCover.imageURL ?? URL(string: "")
        }*/
        
        if (Reachability.isConnectedToNetwork() == false) {
            let alert = DisplayAlert(title: "No internet", message: "Please find an internet connection")
            alert.openAlertError()
            return
        }
        
        let headers = [ "Authorization": "Bearer \(user.token)", "Content-Type": "application/x-www-form-urlencoded"]
        let url = api.getRoute(SounityAPI.ROUTES.CREATE_USER) + "/" + "\(user.id)"
        
        if nickname == nil {
            let alert = DisplayAlert(title: "Invalid parameters", message: "Enter a nickname")
            self.present(alert.getPopAlert() , animated : true, completion : nil)
            return
        }
        if date == nil {
            let alert = DisplayAlert(title: "Invalid parameters", message: "Enter a date")
            self.present(alert.getPopAlert() , animated : true, completion : nil)
            return
        }
        
        let parameters : Parameters = [
            "nickname": nickname! as AnyObject,
            "first_name": firstname! as AnyObject,
            "last_name": lastname! as AnyObject,
            "description": description! as AnyObject,
            "birth_date": date!
        ]
        
        Alamofire.request(url, method: .put, parameters : parameters, headers : headers)
            .validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                Alamofire.request(url, method: .get).responseJSON { response in
                    if let apiResponse = response.result.value {
                        let jsonResponse = JSON(apiResponse)
                        
                        if ((response.response?.statusCode)! != 200) {
                            let alert = DisplayAlert(title: "Edit Profile", message: jsonResponse["message"].stringValue)
                            self.present(alert.getPopAlert() , animated : true, completion : nil)
                        }
                        else {
                            
                            self.user.setHisUsername(jsonResponse["nickname"].stringValue)
                            self.user.setHisFirstName(jsonResponse["first_name"].stringValue)
                            self.user.setHisLastName(jsonResponse["last_name"].stringValue)
                            self.user.setHisBirthday(jsonResponse["birth_date"].stringValue)
                            self.user.setHisDescription(jsonResponse["description"].stringValue)
                            
                            //if (String(newCoverURL!).isEmpty) {
                            self.dismiss(animated: true, completion: nil)
                            //} else {
                            //self.uploadPicture(newCoverURL!)
                            //}
                            
                            let alert = DisplayAlert(title: ("Profil settings"), message: "Your profile has been uploaded")
                            alert.openAlertError()
                        }
                    }
                }
        }
    }
    
    /*func uploadPicture(path: NSURL) {
        getImageFromPath(path, onComplete: {image in
            let api = SounityAPI()
            let headersUpload = [ "Authorization": "Bearer \(self.user.token)", "Accept": "application/json"]
            let urlUploadImage:String = (api.getRoute(SounityAPI.ROUTES.CREATE_USER) + "/image")
            
            Alamofire.upload(.POST, urlUploadImage, headers: headersUpload, multipartFormData: { multipartFormData in
                if let imageData = UIImageJPEGRepresentation(image!, 1) {
                    multipartFormData.appendBodyPart(data: imageData, name: "image", fileName: "user-\(self.user.id)", mimeType: "image/png")
                }},
                encodingMemoryThreshold: Manager.MultipartFormDataEncodingMemoryThreshold,
                encodingCompletion: { encodingResult in
                    switch encodingResult {
                    case .Success(let upload, _, _):
                        upload.responseJSON { response in
                            debugPrint(response)
                            //let data = JSON(response)
                            //self.user.setHisPicture(data["url"].stringValue)
                            let alert = DisplayAlert(title: "Profil settings", message: "Information has been saved.")
                            alert.openAlertSuccess()
                        }
                    case .Failure(let encodingError):
                        print(encodingError)
                        let alert = DisplayAlert(title: ("Upload Picture"), message: String(encodingError))
                        alert.openAlertError()
                    }
            })
        })
    }*/
}

// MARK: Navigation functions
extension UserSettingsViewController {
    @IBAction func cancelButton(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: Create form Eureka
extension UserSettingsViewController {
    func loadSettingsUser() {
        form.keyboardReturnType = nil
        form +++ Section("Settings To Change")
            
            <<< TextRow("nickname"){ row in
                row.title = "Nickname"
                row.tag = "nickname"
                row.value = user.username
            }
            
            <<< TextRow("checkNickname"){ row in
                
                row.value = "This nickname is already used !"
                row.hidden = Condition.function(["nickname"], { form in
                    let rowValue: TextRow? = form.rowBy(tag: "nickname")
                    
                    if (rowValue?.value != nil) {
                        if (rowValue?.value == self.user.username) {
                            self.checkNickname = true
                            return self.checkNickname
                        } else {
                            return self.validate((rowValue?.value)!)
                        }
                    }
                    else {
                        return self.checkNickname
                    }
                })
                }.cellUpdate({ (cell, row) in
                    cell.textField.textColor = UIColor.red
                })
            
            <<< NameRow(){ row in
                row.title = "Firstname"
                row.tag = "firstname"
                row.value = user.firstname
            }
            
            <<< NameRow(){ row in
                row.title = "Last Name"
                row.tag = "lastname"
                row.value = user.lastname
            }
            
            /*<<< ImageRow("picture"){
                $0.title = "Picture"
                $0.tag = "picture"
                $0.sourceTypes = .PhotoLibrary
                $0.clearAction = .no
                let picPath = NSURL(string: self.user.picture)
                let data = NSData(contentsOf: picPath! as URL)
                $0.value = UIImage(data:data! as Data)
            }*/
            
            <<< DateRow("Bith"){
                $0.title = "Birthday"
                if (user.birthday.isEmpty == false) {$0.value = moment(user.birthday)?.date}
                else {$0.value = NSDate() as Date}
                
                $0.tag = "birthday"
            }
            
            +++ Section()
            
            <<< NameRow(){ row in
                row.title = "Description"
                row.tag = "description"
                row.value = user.descriptionUser
            }
            +++ Section()
            
            <<< ButtonRow() { (row: ButtonRow) -> Void in
                row.title = "Send"
                }  .onCellSelection({ (cell, row) in
                    self.showAlert()
                })
    }
}

// MARK: Hide Top Bar
extension UserSettingsViewController {
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
