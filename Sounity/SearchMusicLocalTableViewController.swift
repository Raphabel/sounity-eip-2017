//
//  SearchMusicInLocal.swift
//  Sounity
//
//  Created by Alix FORNIELES on 23/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit
import Foundation
import SwiftyJSON
import Alamofire
import UIKit
import DZNEmptyDataSet

class SearchMusicLocalTableViewController: UIViewController, UITableViewDelegate, UISearchBarDelegate, DZNEmptyDataSetDelegate {
    
    // MARK: Storyboard UIElements
    @IBOutlet var tableview: UITableView!
    @IBOutlet weak var musicSearchBox: UISearchBar!
    
    // MARK: Infos user connected
    var user = UserConnect()

    // MARK: PlaylistID received variable
    var playlist_id: Int = -1

    // MARK: Search box variables
    var timer: Timer? = nil
    var textSearchBox: String = ""
    var searchActive : Bool = false
    var resultResearch = [SounityTrackResearch]()
    
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
    }
}

// MARK: Add music to playlist
extension SearchMusicLocalTableViewController {
    func addMusictToplaylist(_ indexPath: IndexPath) {
        let api = SounityAPI()
        let headers = [ "Authorization": "Bearer \(user.token)", "Accept": "application/json"]
        let parameters : [String : AnyObject] = [
            "id_music": self.resultResearch[indexPath.row].idTrack as AnyObject,
            "apiId": self.resultResearch[indexPath.row].idAPI as AnyObject
        ]
        
        Alamofire.request(api.getRoute(SounityAPI.ROUTES.PLAYLIST_USER) + "/" + "\(playlist_id)" + "/" + "music", method: .post, parameters : parameters, headers: headers)
            .validate(statusCode: 200..<499)
            .validate(contentType: ["application/json"])
            .responseJSON
            {
                response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! == 400) {
                        let alert = DisplayAlert(title: "Add Music", message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        let alert = DisplayAlert(title: "Add Music", message: ("The music : '" + self.resultResearch[indexPath.row].title + " ' has been added."))
                        alert.openAlertSuccess()
                    }
                }
        }
    }
}

// MARk: Empty Table View
extension SearchMusicLocalTableViewController: DZNEmptyDataSetSource {
    // Function that fulfilles the tableview when it's empty
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

// MARK: Search functions
extension SearchMusicLocalTableViewController {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) { searchActive = true; }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) { searchActive = false; }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) { searchActive = false; }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) { searchActive = false; searchBar.resignFirstResponder() }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(SearchMusicLocalTableViewController.searchResultFromString(_:)), userInfo: searchText, repeats: false)
    }
    
    func searchResultFromString(_ timer: Timer) {
        self.textSearchBox = timer.userInfo! as! String
        self.resultResearch.removeAll();

        if (self.textSearchBox == "") {
            return
        }
        
        let api = SounityAPI()
        let headers = [ "Authorization": "Bearer \(self.user.token)", "Accept": "application/json"]
        let parameters = [ "track": self.textSearchBox, "apiId": String(MusicProvider.sharedInstance.apiId) ]
        
        Alamofire.request(api.getRoute(SounityAPI.ROUTES.SEARCH_MUSIC), method: .post, parameters : parameters, headers : headers)
            .validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    
                    if ((response.response?.statusCode)! != 200) {
                        let alert = DisplayAlert(title: "Invalid parameters", message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else { for (_,subJson):(String, JSON) in jsonResponse {
                        self.resultResearch.append(SounityTrackResearch(_jsonResponse: subJson, _music_provider: MusicProvider.sharedInstance.name, _apiId: MusicProvider.sharedInstance.apiId))
                        }
                        self.tableview.reloadData();
                    }
                }
                else {
                    self.tableview.reloadData();
                }
        }
    }
}

// MARK: TableView functions
extension SearchMusicLocalTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:SearchMusicLocalTableViewCell = tableView.dequeueReusableCell(withIdentifier: "SearchMusicLocalTableViewCell", for: indexPath) as! SearchMusicLocalTableViewCell
        
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
        let alert = DisplayAlert(title: "Add this track", message: self.resultResearch[indexPath.row].title)
        alert.openAlertConfirmationWithCallbackAndParameterIndexPath(self.addMusictToplaylist, indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return self.resultResearch.count }
}

// MARK: Hide status bar
extension SearchMusicLocalTableViewController {
    override var prefersStatusBarHidden : Bool {
        return false
    }
}
