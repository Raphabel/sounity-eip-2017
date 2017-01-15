//
//  ManageUserEvent.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 01/01/2017.
//  Copyright © 2017 Degraeve Raphaël. All rights reserved.
//

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

class ManageUserEvent: UIViewController, UICollectionViewDelegate, StatefulViewController, UISearchBarDelegate {
    
    //MARK: UIElements variables
    @IBOutlet var UsersEvent: UICollectionView!
    @IBOutlet weak var userSearchBox: UISearchBar!
    
    //MARK: reuseIdentifier
    let reuseIdentifier = "cellUserEvent"
    
    // MARK: adminsEvent
    var usersEvent = [UserBasicInfo]()
    
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
        
        self.UsersEvent.dataSource = self
        self.UsersEvent.delegate = self
        
        self.userSearchBox.delegate = self
        self.userSearchBox.placeholder = "Search user within Sounity"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.loaded = false
        
        loadingView = LoadingView(_view: self.view)
        setupInitialViewState()
        
        loadUsersFromIdEvent(idEventSent)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}

// MARK: - UICollectionViewDataSource protocol
extension ManageUserEvent: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (self.textSearchBox == "") {
            return self.usersEvent.count
        } else {
            return self.resultResearch.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! InfoUsersEventCell
        
        var tmp: [UserBasicInfo]
        if (self.textSearchBox == "") {
            tmp = self.usersEvent
        } else {
            tmp = self.resultResearch
        }
        
        cell.user = tmp[indexPath.row]
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (self.textSearchBox == "" && self.user.id != self.usersEvent[indexPath.item].id) {
            self.showOptionsUser(userInfo: self.usersEvent[indexPath.item])
        } else if (self.textSearchBox != "" && self.user.id != self.resultResearch[indexPath.item].id) {
            self.showOptionsUser(userInfo: self.resultResearch[indexPath.item])
        }
    }
}

//MARK: StatefulViewController override functions
extension ManageUserEvent {
    func hasContent() -> Bool {
        return self.loaded
    }
    
    func handleErrorWhenContentAvailable(_ error: Error) {
        let alert = DisplayAlert(title: "Ooops", message: "Something went wrong.")
        alert.openAlertError()
    }
}

//MARK: Action on users
extension ManageUserEvent {
    ///  Unbanned user from event
    ///
    /// - Parameter user: user selected [UserBasicInfo]
    func unbannedUserFromEvent(_ user: UserBasicInfo) {
        let idUserToRemove = user.id
        
        let api = SounityAPI()
        let url = (api.getRoute(SounityAPI.ROUTES.GET_INFO_EVENT) + "/" + String(self.idEventSent) + "/" + "ban")
        let headers = [ "Authorization": "Bearer \(self.user.token)", "Accept": "application/json"]
        
        Alamofire.request(url, method: .delete, parameters : ["id": idUserToRemove], headers: headers)
            .validate(statusCode: 200..<500)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! != 200) {
                        let alert = DisplayAlert(title: "Unban User", message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        let alert = DisplayAlert(title: "Unban User", message: ("The user : '\(user.nickname)' has been unbanned."))
                        alert.openAlertSuccess()
                        
                        for (index, elem) in self.usersEvent.enumerated() {
                            if (elem.id == user.id) {
                                self.usersEvent[index].banned = false
                                self.usersEvent[index].participating = false
                            }
                        }
                        
                        for (index, elem) in self.resultResearch.enumerated() {
                            if (elem.id == user.id) {
                                self.resultResearch[index].banned = false
                                self.usersEvent[index].participating = false
                            }
                        }
                        
                        self.UsersEvent.reloadData()
                    }
                }
        }
    }
    
    ///  Ban user from event
    ///
    /// - Parameter user: user selected [UserBasicInfo]
    func banUserToEvent(_ user: UserBasicInfo) {
        SocketIOManager.sharedInstance.banUserFromEvent(datas: ["eventId": self.idEventSent as AnyObject, "token": self.user.token as AnyObject, "userId": user.id as AnyObject], completionHandler: { (datasList) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if !(datasList.null != nil) {
                    if (datasList["status"] == 400) {
                        let alert = DisplayAlert(title: "Ban User", message: datasList["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        let alert = DisplayAlert(title: "Ban User", message: datasList["message"].stringValue)
                        alert.openAlertSuccess()
                        
                        for (index, elem) in self.resultResearch.enumerated() {
                            if (elem.id == user.id) {
                                self.resultResearch[index].banned = true
                                self.usersEvent[index].participating = false
                            }
                        }
                        
                        for (index, elem) in self.usersEvent.enumerated() {
                            if (elem.id == user.id) {
                                self.usersEvent[index].banned = true
                                self.usersEvent[index].participating = false
                            }
                        }
                        
                        self.UsersEvent.reloadData()
                    }
                }
            })
        })
    }
    
    ///  Invite user to an event
    ///
    /// - Parameter user: user selected [UserBasicInfo]
    func inviteUser(_ user: UserBasicInfo) {
        let idUserToInvite = user.id
        
        let api = SounityAPI()
        let url = (api.getRoute(SounityAPI.ROUTES.GET_INFO_EVENT) + String(self.idEventSent) + "/" + "users/invite")
        let headers = [ "Authorization": "Bearer \(self.user.token)", "Accept": "application/json"]
        
        Alamofire.request(url, method: .post, parameters : ["id_user": idUserToInvite], headers: headers)
            .validate(statusCode: 200..<500)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! != 200) {
                        let alert = DisplayAlert(title: "Invite User", message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        let alert = DisplayAlert(title: "Invite User", message: jsonResponse["message"].stringValue)
                        alert.openAlertSuccess()
                    }
                }
        }
    }
    
    func showOptionsUser(userInfo: UserBasicInfo) {
        var message = userInfo.nickname
        
        if (userInfo.banned) {
            message = "\(message) is banned"
        } else if (userInfo.participating) {
            message = "\(message) is participating"
        } else {
            message = "\(message) is not participating"
        }
        
        let optionMenu = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
        
        /*let unbannedUser = UIAlertAction(title: "Unbanned user", style: .destructive, handler: {
            (alert: UIAlertAction!) -> Void in
            let alert = DisplayAlert(title: "Remove ban user", message: ("This function hasn't been coded yet..."))
            alert.openAlertError()
        })*/
        
        let bannedUser = UIAlertAction(title: "Ban user", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.banUserToEvent(userInfo)
        })
        
        let inviteUser = UIAlertAction(title: "Invite user", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.inviteUser(userInfo)
        })
        
        /*let kickUser = UIAlertAction(title: "Kick user", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            let alert = DisplayAlert(title: "Kick user", message: ("This function hasn't been coded yet..."))
            alert.openAlertError()
        })*/
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {
            (alert: UIAlertAction!) -> Void in })
        
        if (userInfo.banned) {
            //optionMenu.addAction(unbannedUser)
        } else if (!userInfo.banned && !userInfo.participating) {
            optionMenu.addAction(inviteUser)
        } else  {
            optionMenu.addAction(bannedUser)
            //optionMenu.addAction(kickUser)
        }
        optionMenu.addAction(cancel)
        
        self.present(optionMenu, animated: true, completion: nil)
    }
}

// MARK: Search box functions
extension ManageUserEvent {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) { searchActive = true; }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) { searchActive = false; }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) { searchActive = false; }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) { searchActive = false; searchBar.resignFirstResponder() }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(ManageAdminEvent.searchResultFromString(_:)), userInfo: searchText, repeats: false)
    }
    
    /// Search function for the user accorcing to their name
    ///
    /// - Parameter timer: timer in order to avoid maing research at every character changed
    func searchResultFromString(_ timer: Timer) {
        self.textSearchBox = timer.userInfo! as! String
        
        if (self.textSearchBox == "") {
            self.loadUsersFromIdEvent(self.idEventSent)
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
                                var bannedTmp: Bool = false
                                var participatingTmp = false
                                for elem: UserBasicInfo in self.usersEvent {
                                    if (elem.id == subJson["id"].intValue) {
                                        bannedTmp = elem.banned
                                        participatingTmp = true
                                    }
                                }
                                self.resultResearch.append(UserBasicInfo(_nickname: subJson["nickname"].stringValue, _id: subJson["id"].intValue, _picture: subJson["picture"].stringValue, _banned: bannedTmp, _participating: participatingTmp))
                            }
                            self.UsersEvent.reloadData()
                        }
                    }
                    self.endLoading()
            }
        } else {
            self.UsersEvent.reloadData()
            
            let alert = DisplayAlert(title: "No connection", message: "Please check your internet connection")
            alert.openAlertError()
        }
    }
}

//MARK: Initialisation functions
extension ManageUserEvent {
    /// Load event's information
    ///
    /// - Parameter idEvent: id of the concerned event
    func loadUsersFromIdEvent(_ idEvent: Int) {
        let api = SounityAPI()
        let parameters = [ "id": idEvent ]
        let headers = [ "Authorization": "Bearer \(user.token)", "Accept": "application/json"]
        
        startLoading()
        
        Alamofire.request("\(api.getRoute(SounityAPI.ROUTES.GET_INFO_EVENT))/\(idEvent)/users", method: .get, parameters: parameters, headers: headers)
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
                        self.usersEvent.removeAll()
                        
                        print(jsonResponse)
                        
                        self.navigationItem.title = "Event's users"
                        
                        for (_,subJson):(String, JSON) in jsonResponse {
                            self.usersEvent.append(UserBasicInfo(_nickname: subJson["nickname"].stringValue, _id: subJson["id"].intValue, _picture: subJson["picture"].stringValue, _banned: subJson["banned"].boolValue, _participating: true))
                        }
                        
                        self.UsersEvent.reloadData()
                    }
                    self.loaded = true
                }
                self.endLoading()
        }
    }
}
