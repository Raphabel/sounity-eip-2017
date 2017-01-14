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
import Photos

class SettingsPlaylistUser: FormViewController {
    
    var eventInfo: Event!
    var user = UserConnect();
    var idPlaylistSent: NSInteger = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ImageRow.defaultCellUpdate = { cell, row in
            cell.accessoryView?.layer.cornerRadius = 17
            cell.accessoryView?.frame = CGRect(0, 0, 34, 34)
        }

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
        var newCoverURL: URL?
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
        if let rowCover = self.form.rowBy(tag: "picture")! as? ImageRow {
            newCoverURL = rowCover.imageURL ?? URL(string: "")
        }
        
        let parameters: Parameters = [
            "id": self.idPlaylistSent,
            "name": newName!,
            "description": newDescription!,
            "public": newPublicInfo!,
        ]
        
        Alamofire.request(api.getRoute(SounityAPI.ROUTES.PLAYLIST_USER_DELETE), method: .put, parameters: parameters, headers: headers)
            .validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! == 400) {
                        let alert = DisplayAlert(title: ("Playlist Save"), message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        if (newCoverURL == nil) {
                            let alert = DisplayAlert(title: ("Playlist settings"), message: "Your playlist has been updated")
                            alert.openAlertSuccess()
                        } else {
                            self.uploadPicture(path: newCoverURL! as NSURL)
                        }
                    }
                }
        }
    }
    
    func uploadPicture(path: NSURL) {
        let fetchResult = PHAsset.fetchAssets(withALAssetURLs: [path.absoluteURL!], options: nil)
        if let photo = fetchResult.firstObject {
            PHImageManager.default().requestImage(for: photo, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: nil) {
                image, info in
                
                let api = SounityAPI()
                let headersUpload = [ "Authorization": "Bearer \(self.user.token)", "Accept": "application/json"]
                let urlUploadImage:String = (api.getRoute(SounityAPI.ROUTES.PLAYLIST_USER_DELETE) + "/\(self.idPlaylistSent)/image")
                
                Alamofire.upload(multipartFormData: { multipartFormData in
                    if let imageData = UIImageJPEGRepresentation(image!, 1) {
                        multipartFormData.append(imageData, withName: "image", fileName: "image.png", mimeType: "image/png")
                    }},
                    to: urlUploadImage, headers: headersUpload,
                    encodingCompletion: { encodingResult in
                        switch encodingResult {
                            case .success(let upload, _, _):
                                upload.responseJSON { response in
                                    if (response.result.isFailure) {
                                        let alert = DisplayAlert(title: ("Upload Picture"), message: "Error while uploading picture")
                                        alert.openAlertError()
                                    } else {
                                        let alert = DisplayAlert(title: "Playlist settings", message: "Information has been saved.")
                                        alert.openAlertSuccess()
                                    }
                                }
                            case .failure(let encodingError):
                                let alert = DisplayAlert(title: ("Upload Picture"), message: String(describing: encodingError))
                                alert.openAlertError()
                            }
                })
            }
        }
    }
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
                        let coverPlaylist = jsonResponse["picture"].stringValue
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
                            <<< ImageRow("picture"){
                                $0.title = "Picture"
                                $0.tag = "picture"
                                $0.sourceTypes = .PhotoLibrary
                                $0.clearAction = .no
                                let picPath = NSURL(string: coverPlaylist)
                                let data = NSData(contentsOf: picPath! as URL)
                                $0.value = data != nil ? UIImage(data:data! as Data) : UIImage(named: "UnknownMusicCover")
                            }
                            
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

extension SettingsPlaylistUser {
    override var prefersStatusBarHidden: Bool {
        return false
    }
}
