//
//  MusicSearchController.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 18/07/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SCLAlertView
import StatefulViewController
import DZNEmptyDataSet

class MusicSearchController: UIViewController, UITableViewDelegate, UISearchBarDelegate, StatefulViewController, DZNEmptyDataSetDelegate {
    
    //MARK: Storyboard UIElements
    @IBOutlet var tableview: UITableView!
    @IBOutlet weak var musicSearchBox: UISearchBar!
    
    //MARK: Infos user connected
    var user = UserConnect();
    
    //MARK: SearchBox variables
    var timer: Timer? = nil
    var textSearchBox: String = ""
    var searchActive : Bool = false
    var resultResearch = [SounityTrackResearch]()
    
    //MARK: User's playlist
    var ownPlaylist = [Playlist]()
    
    //MARK: Music selected to send when user wants to add to his own playlists
    var musicSelectedToAdd: SounityTrackResearch?
    
    //MARK: Tableview prgramatically created to display user's playlists
    var tableviewPopup = UITableView()
    
    // MARK: Override functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.clear
        
        tableview.dataSource = self
        tableview.delegate = self
        tableview.emptyDataSetSource = self
        tableview.emptyDataSetDelegate = self
        tableview.tableFooterView = UIView()
        
        self.musicSearchBox.delegate = self
        self.musicSearchBox.placeholder = "Sounity's musics"
        
        getUserOwnPlaylists()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadingView = LoadingView(_view: self.tableview)
        
        setupInitialViewState()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

//MARK: Feature to add music found to one of the user's playlist
extension MusicSearchController {
    func displayPopupAddToPlaylist() {
        let appearance = SCLAlertView.SCLAppearance(
            showCircularIcon: true,
            kCircleIconHeight: 30,
            kCircleHeight: 55,
            showCloseButton: true,
            shouldAutoDismiss: false,
            hideWhenBackgroundViewIsTapped: true
        )
        
        // Initialize SCLAlertView using custom Appearance
        let alert = SCLAlertView(appearance: appearance)
        
        // Create the subview
        let subview = UIView(frame: CGRect(x: 0,y: 10,width: 200,height: 250))
        
        // Add subtitle
        let label = UILabel(frame: CGRect(x: ((subview.frame.width - 180) / 2),y: 0,width: 190,height: 20))
        label.font = UIFont(name: "TimesNewRomanPS-ItalicMT", size: 12)
        label.text = "Add this song to one of your playlist"
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        subview.addSubview(label)
        
        // Add tableview
        self.tableviewPopup.frame =  CGRect(x: ((subview.frame.width - 180) / 2),y: 40,width: 180,height: 200)
        self.tableviewPopup.delegate = self
        self.tableviewPopup.dataSource = self
        self.tableviewPopup.allowsSelection = true
        self.tableviewPopup.register(UITableViewCell.self, forCellReuseIdentifier: "cellPlaylistName")
        if (self.ownPlaylist.count > 0) {
            subview.addSubview(self.tableviewPopup)
        } else {
            // Add message no playlist
            let labelEmptyPlaylistsList = UILabel(frame: CGRect(x: ((subview.frame.width - 180) / 2),y: 40,width: 190,height: 20))
            labelEmptyPlaylistsList.font = UIFont(name: "TimesNewRomanPS-BoldMT", size: 12)
            labelEmptyPlaylistsList.text = "You don't have any playlist"
            labelEmptyPlaylistsList.textAlignment = .center
            labelEmptyPlaylistsList.lineBreakMode = .byWordWrapping
            labelEmptyPlaylistsList.numberOfLines = 0
            
            subview.addSubview(labelEmptyPlaylistsList)
            subview.frame = CGRect(x: 0,y: 10,width: 200,height: 90)
        }
        alert.customSubview = subview
        _ = alert.showCustom(self.musicSelectedToAdd!.title, subTitle: "", color: ColorSounity.navigationBarColor, icon: UIImage(named: "iconSounityWhite")!, closeButtonTitle: "Cancel")
    }

    func getUserOwnPlaylists() {
        let api = SounityAPI()
        let url = api.getRoute(SounityAPI.ROUTES.CREATE_USER) + "/" + "\(user.id)/playlists"
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
                        for (_,subJson):(String, JSON) in jsonResponse {
                            self.ownPlaylist.append(Playlist(name: subJson["name"].stringValue, create_date: subJson["create_date"].stringValue, id: subJson["id"].intValue, desc: subJson["description"].stringValue, _picture: subJson["picture"].stringValue))
                        }
                    }
                }
        }
    }
    
    func addMusicToUserPlaylist(_ sender: UITapGestureRecognizer) {
        let touch = sender.location(in: tableviewPopup)
        if let indexPath = tableviewPopup.indexPathForRow(at: touch) {
            let api = SounityAPI()
            let headers = [ "Authorization": "Bearer \(user.token)", "Accept": "application/json"]
            let parameters : [String : AnyObject] = [
                "id_music": self.musicSelectedToAdd!.idTrack as AnyObject,
                "apiId": self.musicSelectedToAdd!.idAPI as AnyObject
            ]
            
            Alamofire.request(api.getRoute(SounityAPI.ROUTES.PLAYLIST_USER) + "/" + "\(self.ownPlaylist[indexPath.row].id)" + "/" + "music", method: .post, parameters : parameters, headers: headers)
                .validate(statusCode: 200..<500)
                .validate(contentType: ["application/json"])
                .responseJSON { response in
                    if let apiResponse = response.result.value {
                        let jsonResponse = JSON(apiResponse)
                        if ((response.response?.statusCode)! == 400) {
                            let alert = DisplayAlert(title: "Add Music", message: jsonResponse["message"].stringValue)
                            alert.openAlertError()
                        }
                        else {
                            let alert = DisplayAlert(title: "Add Music", message: ("The music : '\(self.musicSelectedToAdd!.title)' has been added to the playlist '\(self.ownPlaylist[indexPath.row].name)'."))
                            alert.openAlertSuccess()
                        }
                    }
            }
            
        }
    }
}

//MARK: Search Bar Elements
extension MusicSearchController {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) { searchActive = true; }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) { searchActive = false; }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) { searchActive = false; }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) { searchActive = false; searchBar.resignFirstResponder() }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(MusicSearchController.searchResultFromString(_:)), userInfo: searchText, repeats: false)
    }
    
    func searchResultFromString(_ timer: Timer) {
        self.textSearchBox = timer.userInfo! as! String
        
        let api = SounityAPI()
        let headers = [ "Authorization": "Bearer \(self.user.token)", "Accept": "application/json"]
        
        self.resultResearch.removeAll();
        
        let parameters: Parameters = [ "track": self.textSearchBox, "apiId": String(MusicProvider.sharedInstance.apiId) ]
        
        if Reachability.isConnectedToNetwork() == true {
            self.startLoading()
            Alamofire.request(api.getRoute(SounityAPI.ROUTES.SEARCH_MUSIC), method: .post, parameters : parameters, headers: headers)
                .validate(statusCode: 200..<305)
                .validate(contentType: ["application/json"])
                .responseJSON { response in
                    if let apiResponse = response.result.value {
                        let jsonResponse = JSON(apiResponse)
                        if ((response.response?.statusCode)! != 200) {
                            let alert = DisplayAlert(title: "Add Music", message: jsonResponse["message"].stringValue)
                            alert.openAlertError()
                        }
                        else {
                            for (_,subJson):(String, JSON) in jsonResponse {
                                self.resultResearch.append(SounityTrackResearch(_jsonResponse: subJson, _music_provider: MusicProvider.sharedInstance.name, _apiId: MusicProvider.sharedInstance.apiId))
                            }
                            self.tableview.reloadData();
                        }
                    }
                        self.tableview.reloadData();
                    self.endLoading()
                }
        } else {
            self.tableview.reloadData()
            
            let alert = DisplayAlert(title: "No connection", message: "Please check your internet connection")
            alert.openAlertError()
        }
    }
}

//MARK: StatefulViewController implementation functions
extension MusicSearchController {
    func hasContent() -> Bool {
        return resultResearch.count > 0
    }
    
    func handleErrorWhenContentAvailable(_ error: Error) {
        let alert = DisplayAlert(title: "Ooops", message: "Something went wrong.")
        alert.openAlertError()
    }
}


//MARK: Fullfill empty tableview
extension MusicSearchController: DZNEmptyDataSetSource {
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        if (self.textSearchBox == "") {
            return NSMutableAttributedString(string: "")
        }
        let attrsBold = [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 18), NSForegroundColorAttributeName: UIColor.darkGray]
        let attributedString = NSMutableAttributedString(string: "Music not found", attributes: attrsBold)
        
        return attributedString
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        if (self.textSearchBox == "") {
            let str = "Tap on the search box above to find a specific music."
            let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
            return NSAttributedString(string: str, attributes: attrs)
        } else {
            let attributedString = NSMutableAttributedString(string:"Seemingly the following music does not exist : ")
            let attrsBold = [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 14), NSForegroundColorAttributeName: UIColor.darkGray]
            let boldString = NSMutableAttributedString(string:self.textSearchBox, attributes:attrsBold)
            attributedString.append(boldString)
            return attributedString
        }
    }
}

//MARK: Tableview Functions
extension MusicSearchController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if (tableView == self.tableview) {
            let cell:MusicSearchCustomTableCell = tableView.dequeueReusableCell(withIdentifier: "MusicSearchCustomTableCell", for: indexPath) as! MusicSearchCustomTableCell
            
            cell.trackTitle.text = self.resultResearch[indexPath.row].title
            cell.trackArtist.text = self.resultResearch[indexPath.row].artist
            
            if (self.resultResearch[indexPath.row].cover == "") {
                cell.trackPicture.image = UIImage(named: "UnknownMusicCover")!
            }
            else if (Reachability.isConnectedToNetwork() == true) {
                cell.trackPicture.imageFromServerURL(urlString: self.resultResearch[indexPath.row].cover)
                MakeElementRounded().makeElementRounded(cell.trackPicture, newSize: cell.trackPicture.frame.width)
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cellPlaylistName", for: indexPath)
            cell.isUserInteractionEnabled = true
            cell.textLabel?.text = self.ownPlaylist[indexPath.row].name
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MusicSearchController.addMusicToUserPlaylist)))
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (tableView == self.tableview) {
            self.musicSelectedToAdd = self.resultResearch[indexPath.row]
            displayPopupAddToPlaylist()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == self.tableview) {
            return self.resultResearch.count
        } else {
            return ownPlaylist.count
        }
    }

}

