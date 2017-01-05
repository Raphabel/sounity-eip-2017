//
//  UserSearchController.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 18/07/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire
import ImageLoader
import StatefulViewController
import DZNEmptyDataSet

class UserSearchController: UIViewController, UITableViewDelegate, UISearchBarDelegate, StatefulViewController, DZNEmptyDataSetDelegate {
    
    // MARK: UIElements variables
    @IBOutlet var tableview: UITableView!
    @IBOutlet weak var musicSearchBox: UISearchBar!
    
    // MARK: Infos user connected
    var user = UserConnect()
    
    // MARK:  Searchbox variables
    var timer: Timer? = nil
    var textSearchBox : String = ""
    var searchActive : Bool = false
    var resultResearch = [User]()
    var resultFollowers = [Followers]()
    
    // MARK: Override functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableview.dataSource = self
        tableview.delegate = self
        tableview.emptyDataSetSource = self
        tableview.emptyDataSetDelegate = self
        tableview.tableFooterView = UIView()
        
        self.musicSearchBox.delegate = self
        self.musicSearchBox.placeholder = "Search user within Sounity"
        
        getMyFollowers()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadingView = LoadingView(_view: self.tableview)
        
        setupInitialViewState()
    }
    
    // Function that will be called when a user decides to consult a profile
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let userIndex = tableview.indexPathForSelectedRow?.row
        
        if (segue.identifier == "consultProfilController") {
            let navController = segue.destination as! UINavigationController
            let detailController = navController.topViewController as! ConsultProfileController

            detailController.IDUserConsulted = self.resultResearch[userIndex!].id
            detailController.nicknameUserConsulted = self.resultResearch[userIndex!].nickname
            detailController.descriptionUserConsulted = self.resultResearch[userIndex!].description
            detailController.pictureUserConsulted = self.resultResearch[userIndex!].picture
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        let userIndex = tableview.indexPathForSelectedRow?.row
        
        if (identifier == "consultProfilController") {
            if (self.resultResearch[userIndex!].id == user.id) {
                let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Profile", bundle: nil)
                let vc = eventStoryBoard.instantiateViewController(withIdentifier: "ProfileViewID") as! UserHomeViewController
                self.present(vc, animated: true, completion: nil)
                
                return false
            }
        }
        return true
    }
}

// MARK: Search box functions
extension UserSearchController {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) { searchActive = true; }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) { searchActive = false; }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) { searchActive = false; }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) { searchActive = false; searchBar.resignFirstResponder() }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(UserSearchController.searchResultFromString(_:)), userInfo: searchText, repeats: false)
    }
    func searchResultFromString(_ timer: Timer) {
        self.textSearchBox = timer.userInfo! as! String
        
        let api = SounityAPI()
        let parameters = [ "q": timer.userInfo! ]
        let headers = [ "Authorization": "Bearer \(user.token)", "Accept": "application/json"]
        
        self.resultResearch.removeAll();
        
        if Reachability.isConnectedToNetwork() == true {
            self.startLoading()
            Alamofire.request(api.getRoute(SounityAPI.ROUTES.SEARCH_USER), method: .post, parameters : parameters, headers : headers)
                .validate(statusCode: 200..<501)
                .validate(contentType: ["application/json"])
                .responseJSON { response in
                    if let apiResponse = response.result.value {
                        let jsonResponse = JSON(apiResponse)
                        if ((response.response?.statusCode)! == 400) {
                            let alert = DisplayAlert(title: "Search User", message: jsonResponse["message"].stringValue)
                            alert.openAlertError()
                        }
                        else {
                            for (_,subJson):(String, JSON) in jsonResponse["users"] {
                                self.resultResearch.append(User(_description: subJson["description"].stringValue, _first_name: subJson["first_name"].stringValue, _last_name: subJson["last_name"].stringValue, _picture: subJson["picture"].stringValue, _nickname: subJson["nickname"].stringValue, _id: subJson["id"].intValue, _id_country: subJson["id_country"].intValue, _id_language: subJson["id_language"].intValue))
                            }
                            self.tableview.reloadData()
                        }
                    }
                    else {
                        self.tableview.reloadData()
                    }
                    self.endLoading()
                }
        } else {
            self.tableview.reloadData()
            
            let alert = DisplayAlert(title: "No connection", message: "Please check your internet connection")
            alert.openAlertError()
        }
    }
}

//MARK: Get followers of the user
extension UserSearchController {
    func getMyFollowers() {
        let api = SounityAPI()
        
        let url = api.getRoute(SounityAPI.ROUTES.CREATE_USER) + "/" + "\(user.id)" + "/" + "followers"
        Alamofire.request(url, method: .get)
            .validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! == 400) {
                        let alert = DisplayAlert(title: "Add Music", message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        for (_,subJson):(String, JSON) in jsonResponse {
                            self.resultFollowers.append(Followers(_id:subJson["id"].intValue , _lastName: subJson["last_name"].stringValue, _nickName: subJson["nickname"].stringValue, _followedAt: subJson["followed_at"].stringValue, _firstName: subJson["first_name"].stringValue, _picture: subJson["picture"].stringValue, _follow: true))
                        }
                    }
                }
            }
    }
}



//MARK: StatefulViewController implementation functions
extension UserSearchController {
    func hasContent() -> Bool {
        return resultResearch.count > 0
    }
    
    func handleErrorWhenContentAvailable(_ error: Error) {
        let alert = DisplayAlert(title: "Ooops", message: "Something went wrong.")
        alert.openAlertError()
    }
}


//MARK: Fullfill empty tableview
extension UserSearchController: DZNEmptyDataSetSource {
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        if (self.textSearchBox == "") {
            return NSMutableAttributedString(string: "")
        }
        let attrsBold = [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 18), NSForegroundColorAttributeName: UIColor.darkGray]
        let attributedString = NSMutableAttributedString(string: "User not found", attributes: attrsBold)
        
        return attributedString
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        if (self.textSearchBox == "") {
            let str = "Tap on the search box above to find a specific user."
            let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
            return NSAttributedString(string: str, attributes: attrs)
        } else {
            let attributedString = NSMutableAttributedString(string:"Seemingly the following user does not exist : ")
            let attrsBold = [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 14), NSForegroundColorAttributeName: UIColor .darkGray]
            let boldString = NSMutableAttributedString(string:self.textSearchBox, attributes:attrsBold)
            attributedString.append(boldString)
            return attributedString
        }
    }
}

//MARK: TableView Funtions
extension UserSearchController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        
        let cell:UserSearchCustomTableCell = tableView.dequeueReusableCell(withIdentifier: "UserSearchCustomTableCell", for: indexPath as IndexPath) as! UserSearchCustomTableCell
        
        cell.startFollowing.isSelected = false
        for data in resultFollowers {
            if (data.nickname == resultResearch[indexPath.row].nickname) {
                cell.startFollowing.isSelected = true
            }
        }
        
        cell.userName.text = "\(self.resultResearch[indexPath.row].first_name.uppercaseFirst) \(self.resultResearch[indexPath.row].last_name.uppercaseFirst)"
        cell.userUsername.text = self.resultResearch[indexPath.row].nickname.uppercaseFirst
        
        if (self.resultResearch[indexPath.row].picture == "") {
            cell.userPicture.image = UIImage(named: "UnknownUserCover")!
        }
        else if (Reachability.isConnectedToNetwork() == true) {
            cell.userPicture.load.request(with: self.resultResearch[indexPath.row].picture, onCompletion: { image, error, operation in
                if (cell.userPicture.image?.size == nil) {
                    cell.userPicture.image = UIImage(named: "emptyPicture")
                }
                MakeElementRounded().makeElementRounded(cell.userPicture, newSize: cell.userPicture.frame.width)
            })
            
            
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.resultResearch.count
    }
}
