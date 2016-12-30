//
//  PlaylistTableViewController.swift
//  Sounity
//
//  Created by Alix FORNIELES on 01/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SwiftDate
import SwiftMoment
import SCLAlertView
import PullToRefresh
import DZNEmptyDataSet
import StatefulViewController

class AllPlaylistsTableViewController: UITableViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, StatefulViewController {
    
    // MARK: UIElements variables
    @IBOutlet var PlaylistTableView: UITableView!
    
    // MARK: Playlist variables
    var playlists = [Playlist]()
    var nbPlaylist: Int?

    // MARK: API Connection
    var api = SounityAPI()
    
    // MARK: Infos user connected
    var user = UserConnect()
    
    // MARK: Override functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
        self.tableView.tableFooterView = UIView()
    }

    deinit {
        self.tableView.removePullToRefresh(tableView.topPullToRefresh!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let refresher = PullToRefresh()
        tableView.addPullToRefresh(refresher) {
            self.loadSamplePLaylist()
        }
        
        if (!user.checkUserConnected() && self.isViewLoaded) {
            DispatchQueue.main.async(execute: { () -> Void in
                let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Authentication", bundle: nil)
                let vc = eventStoryBoard.instantiateViewController(withIdentifier: "LoginSignUpViewID") as! LoginSignUpController
                self.present(vc, animated: true, completion: nil)
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadSamplePLaylist()
        
        loadingView = LoadingView(_view: self.view)
        setupInitialViewState()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
        if  segue.identifier == "segueMusic1" {
            let nav = segue.destination as! UINavigationController
            let dest = nav.topViewController as! MediaPlayerViewController
            let indexPath = self.PlaylistTableView.indexPathForSelectedRow
            let selectedPlaylist = playlists[(indexPath?.row)!]
            
            dest.id_playlist = selectedPlaylist.id
        }
    }
    
    // MARK: Override function UITableViewController
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {}
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool{
        return indexPath.section == 1 ? true : false
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let deleteAction = UITableViewRowAction(style: .normal, title: "Delete") { (rowAction:UITableViewRowAction, indexPath:IndexPath) -> Void in
            let alert = DisplayAlert(title: "Delete playlist", message: "Do you really want to delete this playlist '" + self.playlists[indexPath.row].name + "'")
            alert.openAlertConfirmationWithCallbackAndParameterIndexPath(self.deletePlaylist, indexPath: indexPath)
        }
        deleteAction.backgroundColor = UIColor(red: CGFloat(0xF4)/255 ,green: CGFloat(0x43)/255 ,blue: CGFloat(0x36)/255 ,alpha: 1)
        
        let createAction = UITableViewRowAction(style: .normal, title: "Event") { (rowAction:UITableViewRowAction, indexPath:IndexPath) -> Void in
            let alert = DisplayAlert(title: "Create event", message: "Do you want to create an event from this playlist '" + self.playlists[indexPath.row].name + "'")
            alert.openAlertConfirmationWithCallbackAndParameterIndexPath(self.createEventFromPlaylist, indexPath: indexPath)
        }
        createAction.backgroundColor = UIColor(red: CGFloat(0xE6)/255 ,green: CGFloat(0x7E)/255 ,blue: CGFloat(0x22)/255 ,alpha: 1)
        
        return [deleteAction, createAction]
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1}
        else {
            return playlists.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddMusic", for: indexPath) as! PlaylistTableViewCell
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(AllPlaylistsTableViewController.displayPopupCreateNewPlaylist(_:))))
            return cell
        }
            
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistTableViewCell", for: indexPath) as! PlaylistTableViewCell
            let playlist = playlists[indexPath.row]
            
            cell.nameLabel.text = playlist.name
            cell.date.text = moment(playlist.create_date)?.format("YYYY-MM-dd HH:mm")
            cell.descriptionPlaylist.text = playlist.desc
            if (playlist.picture == "") {
                cell.picturePlaylist.image = UIImage(named: "UnknownMusicCover")!
            }
            else if (Reachability.isConnectedToNetwork() == true) {
                cell.picturePlaylist.imageFromServerURL(urlString: playlist.picture)
                MakeElementRounded().makeElementRounded(cell.picturePlaylist, newSize: cell.picturePlaylist.frame.width)
            }
            
            return cell
        }
    }
}

// MARK: Empty table view function
extension AllPlaylistsTableViewController {
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let attributedString = NSMutableAttributedString(string:"There is no playlist.")
        return attributedString
    }
}

// MARK: Get all playlists user
extension AllPlaylistsTableViewController {
    func loadSamplePLaylist() {
        self.startLoading()
        let url = api.getRoute(SounityAPI.ROUTES.CREATE_USER) + "/" + "\(user.id)"
        let headers = [ "Authorization": "Bearer \(user.token)", "Content-Type": "application/x-www-form-urlencoded"]
        
        Alamofire.request(url, method: .get, headers: headers)
            .validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! != 200) {
                        let alert = DisplayAlert(title: "Load your playlist", message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        self.playlists.removeAll()
                        
                        for (_,subJson):(String, JSON) in jsonResponse["playlists"] {
                            self.playlists.append(Playlist(name: subJson["name"].stringValue, create_date: subJson["create_date"].stringValue, id: subJson["id"].intValue, desc: subJson["description"].stringValue, _picture: subJson["picture"].stringValue))
                        }
                        self.tableView.endRefreshing(at: Position.top)
                        self.tableView.reloadData()
                    }
                }
                self.endLoading()
        }
    }
}

// MARK: Actions on playlists displayed
extension AllPlaylistsTableViewController {
    func deletePlaylist(_ indexPath: IndexPath) -> Void {
        let api = SounityAPI()
        let headers = [ "Authorization": "Bearer \(self.user.token)", "Accept": "application/json"]
        
        Alamofire.request(api.getRoute(SounityAPI.ROUTES.PLAYLIST_USER_DELETE), method: .delete, parameters: ["id": self.playlists[indexPath.row].id], headers : headers)
            .validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! != 200) {
                        let alert = DisplayAlert(title: "Delete Playlist", message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        self.playlists.remove(at: indexPath.row)
                        self.tableView.deleteRows(at: [indexPath], with: .fade)
                        self.tableView.reloadData()
                        
                        let alert = DisplayAlert(title: "Delete Playlist", message: "Your playlist has been deleted.")
                        alert.openAlertSuccess()
                    }
                }
        }
    }
    
    func createEventFromPlaylist (_ indexPath: IndexPath) {
        let url = (self.api.getRoute(SounityAPI.ROUTES.PLAYLIST_USER) + "/" + "\(self.playlists[indexPath.row].id)" + "/event")
        let headers = [ "Authorization": "Bearer \(user.token)", "Content-Type": "application/x-www-form-urlencoded"]
        
        Alamofire.request(url, method: .post, headers: headers)
            .validate(statusCode: 200..<499)
            .validate(contentType: ["application/json"])
            .responseJSON
            {
                response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! == 400) {
                        let alert = DisplayAlert(title: "Create Event", message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        Alamofire.request(self.api.getRoute(SounityAPI.ROUTES.GET_INFO_EVENT), method: .get, parameters: ["id": jsonResponse["id"].intValue], headers: headers)
                            .validate(statusCode: 200..<499)
                            .validate(contentType: ["application/json"])
                            .responseJSON { response in
                                if let apiResponse = response.result.value {
                                    let jsonResponse = JSON(apiResponse)
                                    if ((response.response?.statusCode)! == 400) {
                                        self.dismiss(animated: true, completion: nil)
                                        let alert = DisplayAlert(title: "Consult Event", message: jsonResponse["message"].stringValue)
                                        alert.openAlertError()
                                    }
                                    else {
                                        let nameEvent = jsonResponse["name"].stringValue
                                        let idEvent = jsonResponse["id"].intValue
                                        
                                        Alamofire.request((self.api.getRoute(SounityAPI.ROUTES.GET_INFO_EVENT) + String(idEvent) + "/start"), method: .post, headers: headers)
                                            .validate(statusCode: 200..<501)
                                            .validate(contentType: ["application/json"])
                                            .responseJSON { response in
                                                if let apiResponse = response.result.value {
                                                    let jsonResponse = JSON(apiResponse)
                                                    if ((response.response?.statusCode)! != 200) {
                                                        let alert = DisplayAlert(title: "Start Event", message: jsonResponse["message"].stringValue)
                                                        alert.openAlertError()
                                                    }
                                                    else {
                                                        let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Event", bundle: nil)
                                                        let vc = eventStoryBoard.instantiateViewController(withIdentifier: "EventViewID") as! EventController
                                                        vc.nameEvent = nameEvent
                                                        vc.idEventSent = idEvent
                                                        vc.owner = true
                                                        self.user.setHisEventJoined(idEvent)
                                                        self.present(vc, animated: true, completion: nil)
                                                        
                                                        let alert = DisplayAlert(title: self.playlists[indexPath.row].name, message: "Your event has been been created.")
                                                        alert.openAlertSuccess()
                                                    }
                                                }
                                        }
                                    }
                                }
                        }
                    }
                }
        }
    }
}

// MARK: Create new playlist
extension AllPlaylistsTableViewController {
    func createNewPlaylist(_ namePlaylist: String, descriptionPlaylist: String, alert: SCLAlertView) {
        let headers = [ "Authorization": "Bearer \(self.user.token)", "Accept": "application/json"]
        let parameters : [String : AnyObject] = [
            "public": 1 as AnyObject,
            "name": namePlaylist as AnyObject,
            "description": descriptionPlaylist as AnyObject,
            "picture": "http://pepseo.fr/wp-content/uploads/2015/03/Live-Events-01.jpg" as AnyObject
        ]
        
        Alamofire.request(self.api.getRoute(SounityAPI.ROUTES.PLAYLIST_USER), method: .post, parameters : parameters, headers: headers)
            .validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! == 400) {
                        let alert = DisplayAlert(title: "Invalid parameters", message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        self.loadSamplePLaylist()
                        alert.hideView()
                    }
                }
        }
    }
    
    func displayPopupCreateNewPlaylist (_ sender: NSObject) {
        let alertAppearance = SCLAlertView.SCLAppearance(
            showCircularIcon: true,
            kCircleIconHeight: 30,
            kCircleHeight: 55,
            showCloseButton: false,
            shouldAutoDismiss: false,
            hideWhenBackgroundViewIsTapped: true
        )
        let alert = SCLAlertView(appearance: alertAppearance)
        let namePlaylistToCreate = alert.addTextField("Playlist's name")
        let descriptionPlaylistToCreate = alert.addTextView()
        
        alert.addButton("Create") {
            if (Reachability.isConnectedToNetwork() == false) {
                alert.hideView()
                
                let alertNoInternet = DisplayAlert(title: "No internet", message: "Please find an internet connection")
                alertNoInternet.openAlertError()
                return
            }
            
            let namePlaylist = namePlaylistToCreate.text!
            let descriptionPlaylist = descriptionPlaylistToCreate.text
            
            if (namePlaylist != "" && descriptionPlaylist != "") {
                self.createNewPlaylist(namePlaylist, descriptionPlaylist: descriptionPlaylist!, alert: alert)
            } else {
                let alertMissingElements = DisplayAlert(title: "Missing elements", message: namePlaylist == "" ? "Playlist's name" : "Playlist's description")
                alertMissingElements.openAlertError()
            }
        }
        
        _ = alert.showCustom("Create new playlist", subTitle: "", color: ColorSounity.orangeSounity, icon: UIImage(named: "playlistIcon")!, closeButtonTitle: "Close")
    }
}
