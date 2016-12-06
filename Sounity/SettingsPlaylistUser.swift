//
//  SettingsPlaylistUser.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 06/11/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Eureka
import Alamofire
import SwiftDate
import SwiftyJSON
import CoreLocation
//import AssetsLibrary

class SettingsPlaylistUser: FormViewController {
    
    var eventInfo: Event!
    var user = UserConnect();
    var idPlaylistSent: NSInteger = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadEventInfo()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    func deletePlaylist() {
        let api = SounityAPI()
        let headers = [ "Authorization": "Bearer \(self.user.token)", "Accept": "application/json"]
        
        let parameters: [String : AnyObject] = [ "id": self.idPlaylistSent as AnyObject ]
        
        Alamofire.request(api.getRoute(SounityAPI.ROUTES.PLAYLIST_USER_DELETE), method: .delete, parameters: parameters, headers: headers)
            .validate(statusCode: 200..<499)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! != 200) {
                        let alert = DisplayAlert(title: ("Playlist delete"), message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        self.dismiss(animated: true, completion: nil)
                        let alert = DisplayAlert(title: "Delete Playlist", message: "Your playlist has been deleted.")
                        alert.openAlertSuccess()
                    }
                }
        }

    }
    
    func saveSettingPlaylist() {
        var newName: String? = ""
        var newDescription: String? = ""
        var newPublicInfo: Bool? = true
        
        let api = SounityAPI()
        let headers = [ "Authorization": "Bearer \(self.user.token)", "Accept": "application/json"]
        
        if let rowName = self.form.rowBy(tag: "name")! as? TextRow {
            newName = rowName.value ?? ""
        }
        if let rowDescription = self.form.rowBy(tag: "description")! as? TextAreaRow {
            newDescription = rowDescription.value ?? ""
        }
        if let rowPublic = self.form.rowBy(tag: "public_playlist")! as? SwitchRow {
            newPublicInfo = rowPublic.value ?? true
        }
        /*if let rowCover = self.form.rowBy(tag: "picturePlaylist")! as? ImageRow {
            newCoverURL = rowCover.imageURL ?? URL(string: "")
        }*/
        
        let parameters: Parameters = [
            "id": self.idPlaylistSent,
            "name": newName!,
            "description": newDescription!,
            "public": newPublicInfo!,
            "picture": /*String(newCoverURL!).isEmpty ? */"http://pepseo.fr/wp-content/uploads/2015/03/Live-Events-01.jpg"// : newCoverURL!
            ]
        
        Alamofire.request(api.getRoute(SounityAPI.ROUTES.PLAYLIST_USER_DELETE), method: .put, parameters: parameters, headers: headers)
            .validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! != 200) {
                        let alert = DisplayAlert(title: ("Playlist Save"), message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        //if (String(newCoverURL!).isEmpty) {
                            let alert = DisplayAlert(title: "Save Playlist", message: "Information has been saved.")
                            alert.openAlertSuccess()
                        //}
                        //else {
                            //self.uploadPicture(newCoverURL!)
                        //}
                    }
                }
        }
    }
    
    /*func uploadPicture(path: NSURL) {
        getImageFromPath(path, onComplete: {image in
            let api = SounityAPI()
            let headersUpload = [ "Authorization": "Bearer \(self.user.token)", "Accept": "application/json"]
            let urlUploadImage:String = (api.getRoute(SounityAPI.ROUTES.PLAYLIST_USER_DELETE) + "\(self.idPlaylistSent)" + "/image")
            
            Alamofire.upload(.POST, urlUploadImage, headers: headersUpload, multipartFormData: { multipartFormData in
                if let imageData = UIImageJPEGRepresentation(image!, 1) {
                    multipartFormData.appendBodyPart(data: imageData, name: "image", fileName: "playlist-\(self.idPlaylistSent)", mimeType: "image/png")
                }},
                encodingMemoryThreshold: Manager.MultipartFormDataEncodingMemoryThreshold,
                encodingCompletion: { encodingResult in
                    switch encodingResult {
                    case .Success(let upload, _, _):
                        upload.responseJSON { response in
                            debugPrint(response)
                            let alert = DisplayAlert(title: "Save Playlist", message: "Information has been saved.")
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
    
    func actionOnEvent (_ _title: String, _msg: String, mode: String) {
        let alert = DisplayAlert(title: _title, message: _msg)
        alert.openAlertConfirmationWithCallback(mode == "delete" ? self.deletePlaylist : self.saveSettingPlaylist)
    }
    
    func loadEventInfo() {
        let api = SounityAPI()
        let url = api.getRoute(SounityAPI.ROUTES.PLAYLIST_USER) + "/\(self.idPlaylistSent)"
        let headers = [ "Authorization": "Bearer \(user.token)", "Content-Type": "application/x-www-form-urlencoded"]
        
        Alamofire.request(url, method: .get, headers: headers)
            .validate(statusCode: 200..<499)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! == 400) {
                        self.dismiss(animated: true, completion: nil)
                        let alert = DisplayAlert(title: "Consult Playlist", message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        let namePlaylist = jsonResponse["name"].stringValue
                        let descriptionPlaylist = jsonResponse["description"].stringValue
                        //let coverPlaylist = jsonResponse["picture"].stringValue
                        let publicPlaylist = jsonResponse["public"].boolValue

                        self.form
                            +++ Section("Playlist name")
                            <<< TextRow("name") {
                                $0.placeholder = "Name"
                                $0.value = namePlaylist
                            }
                            
                            +++ Section("Playlist description")
                            <<< TextAreaRow("description") {
                                $0.placeholder = "Description"
                                $0.value = descriptionPlaylist
                                $0.textAreaHeight = .dynamic(initialTextViewHeight: 40)
                            }
                            
                            +++ Section("Playlist cover")
                            /*<<< ImageRow("picturePlaylist"){
                                $0.title = "Cover"
                                $0.sourceTypes = .PhotoLibrary
                                $0.clearAction = .No
                                let picPath = NSURL(string: coverPlaylist)
                                let data = NSData(contentsOfURL: picPath!)
                                $0.value = UIImage(data:data!)
                            }*/
                            
                            +++ Section("Playlist info")
                            <<< SwitchRow("public_playlist") {
                                $0.title = "Public"
                                $0.value = publicPlaylist
                            }
                            <<< LabelRow(){
                                $0.hidden = Condition.function(["public_playlist"], { form in
                                    return ((form.rowBy(tag: "public_playlist") as? SwitchRow)?.value ?? false)
                                })
                                $0.title = "Your playlist will be hidden.."
                            }
                            +++ Section()
                            <<< ButtonRow() { (row: ButtonRow) -> Void in
                                row.title = "Save"
                                }  .onCellSelection({ (cell, row) in
                                    self.actionOnEvent("Save Settings", _msg: "Do you really want to save these new settings ?", mode: "save")
                                }).cellUpdate { cell, row in
                                    cell.textLabel?.textColor = UIColor.white
                                    cell.backgroundColor = ColorSounity.orangeSounity
                            }
                            +++ Section()
                            <<< ButtonRow() { (row: ButtonRow) -> Void in
                                row.title = "Delete"
                                }  .onCellSelection({ (cell, row) in
                                    self.actionOnEvent("Delete Playlist", _msg: "Do you really want to delete this playlist ?", mode: "delete")
                                }).cellUpdate { cell, row in
                                    cell.textLabel?.textColor = ColorSounity.orangeSounity
                                    cell.backgroundColor = UIColor.white
                        }
                    }
                }
        }
    }
}
/*
func getImageFromPath(path: NSURL, onComplete:((image: UIImage?) -> Void)) {
    let assetsLibrary = ALAssetsLibrary()
    let url = path
    assetsLibrary.assetForURL(url, resultBlock: { (asset) -> Void in
        onComplete(image: UIImage(CGImage: asset.defaultRepresentation().fullResolutionImage().takeUnretainedValue()))
        }, failureBlock: { (error) -> Void in
            onComplete(image: nil)
    })
}*/

extension SettingsPlaylistUser {
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
