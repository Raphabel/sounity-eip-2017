//
//  SearchMusicEventController.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 18/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import UIKit
import DZNEmptyDataSet

class SearchMusicEventController: UIViewController, UITableViewDelegate, UISearchBarDelegate, DZNEmptyDataSetDelegate {
    
    // MARK: Storyboard UIElements
    @IBOutlet var tableview: UITableView!
    @IBOutlet weak var musicSearchBox: UISearchBar!
    
    // MARK: Id event variable
    var idEventSent: NSInteger = -1
    
    // MARK: Infos user connected
    var user = UserConnect()
    
    // MARK: Search box variables
    var timer: Timer? = nil
    var textSearchBox: String = ""
    var searchActive : Bool = false
    var resultResearch = [SounityTrackResearch]()
    
    // MARK: Override functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.idEventSent = user.eventJoined
        
        self.view.backgroundColor = UIColor.clear
        
        tableview.dataSource = self
        tableview.delegate = self
        tableview.emptyDataSetSource = self
        tableview.emptyDataSetDelegate = self
        tableview.tableFooterView = UIView()
        
        self.musicSearchBox.delegate = self
        self.musicSearchBox.placeholder = "Sounity's musics"
    }
    
    /**
     * Called when the user click on the view (outside the UITextField).
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

// MARK: Empty table view
extension SearchMusicEventController: DZNEmptyDataSetSource {
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        if (self.textSearchBox == "") {
            let str = "Tap on the search box above to seek for a specific music."
            let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
            return NSAttributedString(string: str, attributes: attrs)
        }
        else {
            let attributedString = NSMutableAttributedString(string:"No music found for the following text : ")
            let attrsBold = [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 16)]
            let boldString = NSMutableAttributedString(string:self.textSearchBox, attributes:attrsBold)
            attributedString.append(boldString)
            return attributedString
        }
    }
}

// MARK: Search box functions
extension SearchMusicEventController {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) { searchActive = true; }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) { searchActive = false; }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) { searchActive = false; }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) { searchActive = false; searchBar.resignFirstResponder() }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(SearchMusicEventController.searchResultFromString(_:)), userInfo: searchText, repeats: false)
    }
    
    func searchResultFromString(_ timer: Timer) {
        self.textSearchBox = timer.userInfo! as! String
        
        let api = SounityAPI()
        let headers = [ "Authorization": "Bearer \(self.user.token)", "Accept": "application/json"]
        
        self.resultResearch.removeAll();
        
        let parameters = [ "track": self.textSearchBox, "apiId": String(MusicProvider.sharedInstance.apiId) ]
        
        Alamofire.request(api.getRoute(SounityAPI.ROUTES.SEARCH_MUSIC), method: .post, parameters : parameters, headers : headers)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    for (_,subJson):(String, JSON) in jsonResponse {
                        self.resultResearch.append(SounityTrackResearch(_jsonResponse: subJson, _music_provider: MusicProvider.sharedInstance.name, _apiId: MusicProvider.sharedInstance.apiId))
                    }
                    self.tableview.reloadData();
                }
                else {
                    self.tableview.reloadData();
                }
        }
    }
}

// MARK: Add song to the event playlist
extension SearchMusicEventController {
    func addNewSongToPlaylistEvent(_ indexPath: IndexPath) {
        SocketIOManager.sharedInstance.addMusicToEventPlaylist(datas: ["id": self.resultResearch[indexPath.row].idTrack as AnyObject, "eventId": self.idEventSent as AnyObject, "token": self.user.token as AnyObject, "apiId": self.resultResearch[indexPath.row].idAPI as AnyObject], completionHandler: { (datasList) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if !(datasList.null != nil) {
                    if (datasList["status"] == 400) {
                        let alert = DisplayAlert(title: "Add music", message: datasList["message"].stringValue)
                        alert.openAlertError()
                    } else {
                        let barViewControllers = self.tabBarController?.viewControllers
                        let svc = barViewControllers![0] as! PlaylistEventController
                        if (datasList["like"].exists()) {
                            let dateFormatter = DateFormatter()
                            let enUSPosixLocale = NSLocale(localeIdentifier: "en_US_POSIX")
                            dateFormatter.locale = enUSPosixLocale as Locale!
                            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                            let myDate = dateFormatter.string(from: NSDate() as Date)
                            
                            svc.playlist.insert(MusicPlaylistEvent(_id: datasList["id"].intValue, _apiId: datasList["apiId"].intValue, _artist: self.resultResearch[indexPath.row].artist, _title: self.resultResearch[indexPath.row].title, _url: self.resultResearch[indexPath.row].streamLink, _cover: self.resultResearch[indexPath.row].cover, _duration: Double(self.resultResearch[indexPath.row].duration), _addedBy: self.user.username, _addedAt: myDate, _like: 1, _dislike: 0, _liked: true, _disliked: false), at: datasList["newPos"].intValue)
                            svc.tableview.reloadData()
                            
                        } else {
                            for elem in svc.playlist {
                                if (elem.id == datasList["id"].intValue) {
                                    elem.like = datasList["like"].intValue
                                }
                            }
                        }
                        
                        if (!SocketIOManager.sharedInstance.registerNewTransaction(idTransactionReceived: datasList["transactionId"].intValue)) {
                            let barViewControllers = self.tabBarController?.viewControllers
                            let svc = barViewControllers![EventController.TABITEM.playlist.rawValue] as! PlaylistEventController
                            svc.getPlaylistEvent()
                        }
                        
                        let alert = DisplayAlert(title: "Add music", message: "Music added with success.")
                        alert.openAlertSuccess()
                    }
                }
            })
        })
    }
}

// MARK: Table view function
extension SearchMusicEventController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:SearchMusicEventCustomTableCell = tableView.dequeueReusableCell(withIdentifier: "SearchMusicEventCustomTableCell", for: indexPath) as! SearchMusicEventCustomTableCell
        
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
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("idTrack selected to add in event : \(self.resultResearch[indexPath.row].idTrack)")
        let alert = DisplayAlert(title: "Add this track", message: self.resultResearch[indexPath.row].title)
        alert.openAlertConfirmationWithCallbackAndParameterIndexPath(self.addNewSongToPlaylistEvent, indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.resultResearch.count
    }
}
