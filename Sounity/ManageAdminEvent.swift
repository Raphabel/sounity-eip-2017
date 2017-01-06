//
//  manageAdminEvent.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 01/01/2017.
//  Copyright © 2017 Degraeve Raphaël. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire
import StatefulViewController

class ManageAdminEvent: UIViewController, UICollectionViewDelegate, StatefulViewController, UISearchBarDelegate {
    
     //MARK: UIElements variables
    @IBOutlet var AdminsEvent: UICollectionView!
    @IBOutlet weak var userSearchBox: UISearchBar!
    
    //MARK: reuseIdentifier
    let reuseIdentifier = "cellAdminEvent"
    
    // MARK: adminsEvent
    var adminsEvent = [UserBasicInfo]()
    
    // MARK: Result research
    var resultResearch = [UserBasicInfo]()
    
    //MARK: Info user connected
    var user = UserConnect();
    
    //MARK: SearchBox variables
    var timer: Timer? = nil
    var textSearchBox : String = ""
    var searchActive : Bool = false
    
    //MARK: Variable received from segue
    var idEventSent: NSInteger = -1
    
    //MARK: State of the page
    var loaded: Bool = false
    
    // MARK: Override functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.AdminsEvent.dataSource = self
        self.AdminsEvent.delegate = self
        
        self.userSearchBox.delegate = self
        self.userSearchBox.placeholder = "Search user within Sounity"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.loaded = false
        
        loadingView = LoadingView(_view: self.view)
        setupInitialViewState()
        
        loadFromIdEvent(idEventSent)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}

// MARK: - UICollectionViewDataSource protocol
extension ManageAdminEvent: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (self.textSearchBox == "") {
            return self.adminsEvent.count
        } else {
            return self.resultResearch.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! InfoUsersEventCell
        
        var tmp: [UserBasicInfo]
        if (self.textSearchBox == "") {
            tmp = self.adminsEvent
        } else {
            tmp = self.resultResearch
        }
        
        cell.userName.text = tmp[indexPath.item].nickname
        cell.pictureUser.load.request(with: tmp[indexPath.item].picture, onCompletion: { image, error, operation in
            if (cell.pictureUser.image?.size == nil) {
                cell.pictureUser.image = UIImage(named: "emptyPicture")
            }
            MakeElementRounded().makeElementRounded(cell.pictureUser, newSize: cell.pictureUser.frame.width)
        })
        
        if (tmp[indexPath.item].owner) {
            cell.backgroundColor = ColorSounity.orangeSounity
        } else if (tmp[indexPath.item].admin) {
            cell.backgroundColor = ColorSounity.navigationBarColor
        } else {
            cell.backgroundColor = UIColor.lightGray
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (self.textSearchBox == "") {
            if (!self.adminsEvent[indexPath.item].owner && self.user.id != self.adminsEvent[indexPath.item].id) {
                self.showOptionsUser(userInfo: self.adminsEvent[indexPath.item])
            }
        } else {
            if (!self.resultResearch[indexPath.item].owner && self.user.id != self.resultResearch[indexPath.item].id) {
                self.showOptionsUser(userInfo: self.resultResearch[indexPath.item])
            }
        }
    }
}

//MARK: StatefulViewController override functions
extension ManageAdminEvent {
    func hasContent() -> Bool {
        return self.loaded
    }
    
    func handleErrorWhenContentAvailable(_ error: Error) {
        let alert = DisplayAlert(title: "Ooops", message: "Something went wrong.")
        alert.openAlertError()
    }
}

//MARK: Action on users
extension ManageAdminEvent {
    func removeAdminFromEvent(_ user: UserBasicInfo) {
        let idUserToRemove = user.id
        
        let api = SounityAPI()
        let url = (api.getRoute(SounityAPI.ROUTES.GET_INFO_EVENT) + "/" + String(self.idEventSent) + "/" + "admin")
        let headers = [ "Authorization": "Bearer \(self.user.token)", "Accept": "application/json"]
        
        Alamofire.request(url, method: .delete, parameters : ["id": idUserToRemove], headers: headers)
            .validate(statusCode: 200..<500)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! == 400) {
                        let alert = DisplayAlert(title: "Remove Admin", message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        let alert = DisplayAlert(title: "Remove Admin", message: ("The user : '\(user.nickname)' has been removed from event's admin."))
                        alert.openAlertSuccess()
                        
                        for (index, elem) in self.adminsEvent.enumerated() {
                            if (elem.id == user.id) {
                                self.adminsEvent.remove(at: index)
                            }
                        }
                        self.AdminsEvent.reloadData()
                    }
                }
        }
    }
    
    func addAdminToEvent(_ user: UserBasicInfo) {
        let idUserToRemove = user.id
        
        let api = SounityAPI()
        let url = (api.getRoute(SounityAPI.ROUTES.GET_INFO_EVENT) + "/" + String(self.idEventSent) + "/" + "admin")
        let headers = [ "Authorization": "Bearer \(self.user.token)", "Accept": "application/json"]
        
        Alamofire.request(url, method: .post, parameters : ["id": idUserToRemove], headers: headers)
            .validate(statusCode: 200..<500)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! == 400) {
                        let alert = DisplayAlert(title: "Add Admin", message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        let alert = DisplayAlert(title: "Add Admin", message: ("The user : '\(user.nickname)' has been added as an admin."))
                        alert.openAlertSuccess()
                        
                        for (index, elem) in self.resultResearch.enumerated() {
                            if (elem.id == user.id) {
                                self.resultResearch[index].admin = true
                            }
                        }
                        self.AdminsEvent.reloadData()
                    }
                }
        }
    }
    
    func showOptionsUser(userInfo: UserBasicInfo) {
        let optionMenu = UIAlertController(title: nil, message: userInfo.nickname, preferredStyle: .actionSheet)
        
        let removeAdmin = UIAlertAction(title: "Remove admin", style: .destructive, handler: {
            (alert: UIAlertAction!) -> Void in
            self.removeAdminFromEvent(userInfo)
        })
        
        let addAdmin = UIAlertAction(title: "Mark as Admin", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.addAdminToEvent(userInfo)
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {
            (alert: UIAlertAction!) -> Void in })
        
        if (userInfo.admin) {
            optionMenu.addAction(removeAdmin)
        } else if (!userInfo.admin) {
            optionMenu.addAction(addAdmin)
        }
        optionMenu.addAction(cancel)
        
        self.present(optionMenu, animated: true, completion: nil)
    }
}

// MARK: Search box functions
extension ManageAdminEvent {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) { searchActive = true; }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) { searchActive = false; }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) { searchActive = false; }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) { searchActive = false; searchBar.resignFirstResponder() }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(ManageAdminEvent.searchResultFromString(_:)), userInfo: searchText, repeats: false)
    }
    func searchResultFromString(_ timer: Timer) {
        self.textSearchBox = timer.userInfo! as! String
        
        if (self.textSearchBox == "") {
            self.loadFromIdEvent(self.idEventSent)
            return
        }
        
        let api = SounityAPI()
        let parameters = [ "q": timer.userInfo! ]
        let headers = [ "Authorization": "Bearer \(user.token)", "Accept": "application/json"]
        
        self.resultResearch.removeAll();
        
        if Reachability.isConnectedToNetwork() == true {
            self.startLoading()
            Alamofire.request(api.getRoute(SounityAPI.ROUTES.SEARCH_USER), method: .post, parameters : parameters, headers : headers)
                .validate(statusCode: 200..<305)
                .validate(contentType: ["application/json"])
                .responseJSON { response in
                    if let apiResponse = response.result.value {
                        let jsonResponse = JSON(apiResponse)
                        if ((response.response?.statusCode)! != 200) {
                            let alert = DisplayAlert(title: "Search User", message: jsonResponse["message"].stringValue)
                            alert.openAlertError()
                        }
                        else {
                            self.resultResearch.removeAll()
                            for (_,subJson):(String, JSON) in jsonResponse["users"] {
                                var ownerTmp: Bool = false
                                var adminTmp: Bool = false
                                for elem: UserBasicInfo in self.adminsEvent {
                                    if (elem.id == subJson["id"].intValue) {
                                        ownerTmp = elem.owner
                                        adminTmp = elem.admin
                                    }
                                }
                                self.resultResearch.append(UserBasicInfo(_nickname: subJson["nickname"].stringValue, _id: subJson["id"].intValue, _picture: subJson["picture"].stringValue, _owner: ownerTmp, _admin: adminTmp))
                            }
                            self.AdminsEvent.reloadData()
                        }
                    }
                    self.endLoading()
            }
        } else {
            self.AdminsEvent.reloadData()
            
            let alert = DisplayAlert(title: "No connection", message: "Please check your internet connection")
            alert.openAlertError()
        }
    }
}

//MARK: AdminInfoClass 
extension ManageAdminEvent {
    class UserBasicInfo {
        var nickname: String
        var picture: String

        var id: Int

        var owner: Bool
        var admin: Bool
        
        init(_nickname: String, _id: Int, _picture: String, _owner: Bool, _admin: Bool) {
            self.nickname = _nickname
            self.id = _id
            self.picture = _picture
            self.owner = _owner
            self.admin = _admin
        }
    }
}

//MARK: Initialisation functions
extension ManageAdminEvent {
    func loadFromIdEvent(_ idEvent: Int) {
        let api = SounityAPI()
        let parameters = [ "id": idEvent ]
        let headers = [ "Authorization": "Bearer \(user.token)", "Accept": "application/json"]
        
        startLoading()
        
        Alamofire.request(api.getRoute(SounityAPI.ROUTES.GET_INFO_EVENT), method: .get, parameters: parameters, headers: headers)
            .validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! == 400) {
                        self.dismiss(animated: true, completion: nil)
                        let alert = DisplayAlert(title: "Get Admins Event", message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        self.adminsEvent.removeAll()
                        
                        self.navigationItem.title = "Event's admins"
                        
                        self.adminsEvent.append(UserBasicInfo(_nickname: jsonResponse["owner"]["nickname"].stringValue, _id: jsonResponse["owner"]["id"].intValue, _picture: jsonResponse["owner"]["picture"].stringValue, _owner: true, _admin: false))
                        
                        for (_,subJson):(String, JSON) in jsonResponse["admins"] {
                            self.adminsEvent.append(UserBasicInfo(_nickname: subJson["nickname"].stringValue, _id: subJson["id"].intValue, _picture: subJson["picture"].stringValue, _owner: false, _admin: true))
                        }
                        
                        self.AdminsEvent.reloadData()
                    }
                    self.loaded = true
                }
                self.endLoading()
        }
    }
}