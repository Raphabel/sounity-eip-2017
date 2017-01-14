//
//  ConsultProfileController.swift
//  Sounity
//
//  Created by Alix FORNIELES on 07/10/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit
import GuillotineMenu
import AVFoundation
import Alamofire
import SwiftyJSON
import SwiftMoment
import SwiftDate
import FaveButton
import PullToRefresh

class ConsultProfileController: UIViewController, UITableViewDelegate {
    
    //MARK: UIElements variables
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nickname: UILabel!
    @IBOutlet weak var nmFollowers: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var PView: UIView!
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var descriptionUser: UILabel!
    @IBOutlet weak var followCornerButton: UIButton!
    @IBOutlet weak var unfollowCornerButton: UIButton!
    
    //MARK:  API instance in order tomake request with right URLs
    var api = SounityAPI()
    
    //MARK:  Infos user connected
    var userConnect = UserConnect()

    //MARK:  Info of the consulted profile
    var user = User()
    var playlists = [Playlist]()
    var IDUserConsulted: Int?
    var nicknameUserConsulted: String?
    var descriptionUserConsulted: String?
    var pictureUserConsulted: String?
    var nbPlaylist: Int?
    
    //MARK:  Users that the current user followed
    var resultFollowersConsulted = [Followers]()
    var resultFollowers = [Followers]()
    
    // MARK: Override functions
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        self.setUpHeaderProfil()
        self.getFollowers()
        self.loadSamplePLaylist(user.id)
    }
    
    deinit {
        self.tableView.removePullToRefresh(tableView.topPullToRefresh!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let refresher = PullToRefresh()
        tableView.addPullToRefresh(refresher) {
            self.loadSamplePLaylist(self.user.id)
        }
        
        if (!userConnect.checkUserConnected() && self.isViewLoaded) {
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if  segue.identifier == "segueMusic1" {
            let nav = segue.destination as! UINavigationController
            let dest = nav.topViewController as! ConsultMusicsInPlaylistController
            let indexPath = self.tableView.indexPathForSelectedRow
            let selectedPlaylist = playlists[(indexPath?.row)!]
            
            dest.id_playlist = selectedPlaylist.id
        }
    }
}

//MARK: Initilisation functions
extension ConsultProfileController {
    /// Function to setup the page headear with the informatio of the user
    func setUpHeaderProfil () {
        if (self.userConnect.id == self.IDUserConsulted) {
            self.settingButton.isHidden = false
        } else {
            self.settingButton.isHidden = true
        }
        
        self.nickname.text = nicknameUserConsulted
        self.descriptionUser.text = descriptionUserConsulted
        self.user.setNickname(nicknameUserConsulted!)
        self.user.setIDprofile(IDUserConsulted!)
        
        self.imageView.layer.masksToBounds = true
        _ = self.putShadowOnView(self.imageView, shadowColor: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), radius: 10, offset: CGSize(width: 0, height: 0), opacity: 1)
        
        if self.pictureUserConsulted == "" {
            self.imageView.image = UIImage(named: "UnknownUserCover")!
        } else if (Reachability.isConnectedToNetwork() == true) {
            self.imageView.load.request(with: self.pictureUserConsulted!, onCompletion: { image, error, operation in
                if (self.imageView.image?.size == nil) {
                    self.imageView.image = UIImage(named: "emptyPicture")
                }
                MakeElementRounded().makeElementRounded(self.imageView, newSize: self.imageView.frame.width)
            })
        }
    }
    
    /// Puts a show on a view
    ///
    /// - Parameters:
    ///   - viewToWorkUpon: view involved
    ///   - shadowColor: color of the shadow
    ///   - radius: radius to apply
    ///   - offset: offset to apply
    ///   - opacity: opacity to apply
    /// - Returns: return UIView built
    func putShadowOnView(_ viewToWorkUpon:UIView, shadowColor:UIColor, radius:CGFloat, offset:CGSize, opacity:Float)-> UIView {
        var shadowFrame = CGRect.zero
        shadowFrame.size.width = viewToWorkUpon.frame.width
        shadowFrame.size.height = viewToWorkUpon.frame.height
        shadowFrame.origin.x = 0
        shadowFrame.origin.y = 0
        
        let shadow = UIView(frame: shadowFrame)
        shadow.isUserInteractionEnabled = true;
        shadow.layer.shadowColor = shadowColor.cgColor
        shadow.layer.shadowOffset = offset
        shadow.layer.shadowRadius = 50
        shadow.layer.masksToBounds = false
        shadow.clipsToBounds = false
        shadow.layer.shadowOpacity = opacity
        viewToWorkUpon.superview?.insertSubview(shadow, belowSubview: viewToWorkUpon)
        
        shadow.addSubview(viewToWorkUpon)
        return shadow
    }
}

//MARK: Get playlist consulted user's profile
extension ConsultProfileController {
    /// Load playlist of the user consulted
    ///
    /// - Parameter IDProfile: user's ID
    func loadSamplePLaylist(_ IDProfile: Int)  {
        
        let url = api.getRoute(SounityAPI.ROUTES.CREATE_USER) + "/" + "\(IDProfile)/playlists"
        let headers = [ "Authorization": "Bearer \(userConnect.token)", "Content-Type": "application/x-www-form-urlencoded"]
        
        Alamofire.request(url, method: .get, headers: headers)
            .validate(statusCode: 200..<499)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! == 400) {
                        self.dismiss(animated: true, completion: nil)
                        let alert = DisplayAlert(title: "My profile", message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        self.playlists.removeAll();
                        self.nbPlaylist = 0
                        
                        for (_,_):(String, JSON) in jsonResponse {
                            let _name = jsonResponse[self.nbPlaylist!]["name"]
                            let _create_date = jsonResponse[self.nbPlaylist!]["create_date"]
                            let _id = jsonResponse[self.nbPlaylist!]["id"]
                            let _description = jsonResponse[self.nbPlaylist!]["description"]
                            let _picture = jsonResponse[self.nbPlaylist!]["picture"]
                            let playlist = Playlist(name: _name.stringValue, create_date: _create_date.stringValue, id: _id.intValue, desc: _description.stringValue, _picture: _picture.stringValue)
                            
                            self.playlists.append(playlist)
                            self.nbPlaylist! += 1
                        }
                        self.tableView.endRefreshing(at: Position.top)
                        self.tableView.reloadData()
                    }
                }
                else { self.tableView.endRefreshing(at: Position.top); self.tableView.reloadData() }
        }
        
    }
}

//MARK: Navigation within the profile
extension ConsultProfileController {
    @IBAction func goToSettingUser(_ sender: AnyObject) {
        let mainStoryboard = UIStoryboard(name: "Profile", bundle: Bundle.main)
        let myVC = mainStoryboard.instantiateViewController(withIdentifier: "UserSettingViewID") as UIViewController
        let navController = UINavigationController.init(rootViewController: myVC)
        self.navigationController?.present(navController, animated: true, completion: nil)
    }
    
    @IBAction func backButton(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }

}

//MARK: Followers handling
extension ConsultProfileController {
    /// Get the followers of the consulted user
    func getFollowers() {
        self.followCornerButton.layer.cornerRadius = 20
        self.followCornerButton.clipsToBounds = true
        self.followCornerButton.setTitle("FOLLOW", for: UIControlState())
        self.followCornerButton.backgroundColor = UIColor(red: CGFloat(0x41)/255 ,green: CGFloat(0x3E)/255 ,blue: CGFloat(0x4F)/255 ,alpha: 1)
        self.followCornerButton.tag = 0
        self.followCornerButton.addTarget(self, action: #selector(ConsultProfileController.followButtonAction(_:)), for: .touchUpInside)
        
        Alamofire.request((api.getRoute(SounityAPI.ROUTES.CREATE_USER) + "/" + "\(user.id)" + "/" + "followers"), method: .get)
            .validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! != 200) {
                        let alert = DisplayAlert(title: ("Get Followers"), message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        for (_,subJson):(String, JSON) in jsonResponse {
                            self.resultFollowersConsulted.append(Followers(_id:subJson["id"].intValue , _lastName: subJson["last_name"].stringValue, _nickName: subJson["nickname"].stringValue, _followedAt: subJson["followed_at"].stringValue, _firstName: subJson["first_name"].stringValue, _picture: subJson["picture"].stringValue, _follow: true))
                        }
                        if self.user.id == self.userConnect.id {
                            self.followCornerButton.tag = 1
                            self.followCornerButton.setTitle("UNFOLLOW", for: .normal)
                        }
                    }
                    self.nmFollowers.text = String(self.resultFollowersConsulted.count)
                }
        }
        
        /// Get all the followers to the current user in order to know if the consulted user is already followed or not
        Alamofire.request((api.getRoute(SounityAPI.ROUTES.CREATE_USER) + "/" + "\(userConnect.id)" + "/" + "followers"), method: .get)
            .validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! != 200) {
                        let alert = DisplayAlert(title: ("Get Followers"), message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        for (_,subJson):(String, JSON) in jsonResponse {
                            self.resultFollowers.append(Followers(_id:subJson["id"].intValue , _lastName: subJson["last_name"].stringValue, _nickName: subJson["nickname"].stringValue, _followedAt: subJson["followed_at"].stringValue, _firstName: subJson["first_name"].stringValue, _picture: subJson["picture"].stringValue, _follow: true))
                        }
                    }
                }
                for data in self.resultFollowers {
                    if data.nickname == self.user.nickname {
                        self.followCornerButton.tag = 1
                        self.followCornerButton.setTitle("UNFOLLOW", for: .normal)
                    }
                }
        }
    }
    
    /// Action to follow | unfollow the consulted user
    ///
    /// - Parameter sender: sender related to the button that allows to get the button's tag [0 (request follow) || 1 (request unfollow)]
    @IBAction func followButtonAction(_ sender: AnyObject) {
        if sender.tag == 1 {
            
            let api = SounityAPI()
            let url = api.getRoute(SounityAPI.ROUTES.CREATE_USER) + "/" + "\(user.id)" + "/follower"
            let headers = [ "Authorization": "Bearer \(userConnect.token)", "Accept": "application/json"]
            
            Alamofire.request(url, method: .delete, headers : headers)
                .validate(statusCode: 200..<501)
                .validate(contentType: ["application/json"])
                .responseJSON { response in
                    if let apiResponse = response.result.value {
                        let jsonResponse = JSON(apiResponse)
                        if ((response.response?.statusCode)! != 200) {
                            let alert = DisplayAlert(title: "Unfollow user", message: jsonResponse["message"].stringValue)
                            alert.openAlertError()
                        }
                        else {
                            self.followCornerButton.tag = 0
                            self.followCornerButton.setTitle("FOLLOW", for: UIControlState())
                            
                            let alert = DisplayAlert(title: "Unfollow", message: jsonResponse["message"].stringValue)
                            alert.openAlertSuccess()
                        }
                    }
            }
            
        } else {
            
            let api = SounityAPI()
            let url = api.getRoute(SounityAPI.ROUTES.CREATE_USER) + "/" + "\(user.id)" + "/follower"
            let headers = [ "Authorization": "Bearer \(userConnect.token)", "Accept": "application/json"]
            
            Alamofire.request(url, method: .post, headers : headers)
                .validate(statusCode: 200..<501)
                .validate(contentType: ["application/json"])
                .responseJSON { response in
                    if let apiResponse = response.result.value {
                        let jsonResponse = JSON(apiResponse)
                        if ((response.response?.statusCode)! != 200) {
                            let alert = DisplayAlert(title: "Follow user", message: jsonResponse["message"].stringValue)
                            alert.openAlertError()
                        }
                        else {
                            self.followCornerButton.tag = 1
                            self.followCornerButton.setTitle("UNFOLLOW", for: UIControlState())

                            let alert = DisplayAlert(title: "Follow", message: jsonResponse["message"].stringValue)
                            alert.openAlertSuccess()
                        }
                    }
            }
        }
    }
}

//MARK: Functions related to the table View
extension ConsultProfileController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlists.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistTableViewCell", for: indexPath) as! PlaylistTableViewCell
        
        cell.playlist = self.playlists[indexPath.row]
        
        return cell
    }
}

extension ConsultProfileController {
    override var prefersStatusBarHidden : Bool {
        return false
    }
}
