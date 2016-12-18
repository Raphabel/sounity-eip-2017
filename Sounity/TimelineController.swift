//  TimelineController.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 17/11/2016.
//  Copyright © 2016 Fornieles Alix. All rights reserved.
//

import UIKit
import GuillotineMenu
import Alamofire
import SwiftyJSON
import PullToRefresh
import SwiftMoment
import SwiftDate
import DZNEmptyDataSet

class TimelineController: UIViewController, DZNEmptyDataSetDelegate {
    
    // MARK: Getter of the current week
    var currentWeek: Date {
        return Calendar(identifier: .iso8601).date(from: Calendar(identifier: .iso8601).dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
    }
    
    // MARK: Infos user connected
    var user = UserConnect()
    
    // MARK: API connection
    var api = SounityAPI()
    
    // MARK: StoryBoard UIElements
    @IBOutlet var tableview: UITableView!
    var newsFromWeekNumber: Int = 0
    var newfeeds = [newFeed]()
    
    // MARK: Guillotine menu variable
    fileprivate lazy var presentationAnimator = GuillotineTransitionAnimation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableview.delegate = self
        self.tableview.dataSource = self
        self.tableview.emptyDataSetSource = self
        self.tableview.emptyDataSetDelegate = self
        self.tableview.tableFooterView = UIView()
        self.tableview.rowHeight = UITableViewAutomaticDimension
        self.tableview.estimatedRowHeight = 80
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GetTimelineUser()
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

//MARK: Functions related to the table View
extension TimelineController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellTimeline", for: indexPath) as? TimelineTableViewCell
        
        cell!.date.text = self.newfeeds[indexPath.row].created_date
        cell?.timelineUserInfo.text = self.newfeeds[indexPath.row].message
        
        if (self.newfeeds[indexPath.row].picture == "") {
            cell?.picture.image = UIImage(named: "UnknownUserCover")!
        }
        else if (Reachability.isConnectedToNetwork() == true) {
            cell?.picture.imageFromServerURL(urlString: self.newfeeds[indexPath.row].picture)
            MakeElementRounded().makeElementRounded(cell?.picture, newSize: cell?.picture.frame.width)
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newfeeds.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.newfeeds[indexPath.row].message.lowercased().range(of: "event") != nil {
            let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Search", bundle: nil)
            
            let vc = eventStoryBoard.instantiateViewController(withIdentifier: "ConsultEventView") as! ConsultEventController
            vc.idEventSent = self.newfeeds[indexPath.row].eventInfo!.id
            let navController = UINavigationController.init(rootViewController: vc)
            self.present(navController, animated: true, completion: nil)
        }
            
        else if self.newfeeds[indexPath.row].message.lowercased().range(of: "profile") != nil {
            if (self.newfeeds[indexPath.row].user.id == user.id) {
                let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Profile", bundle: nil)
                let vc = eventStoryBoard.instantiateViewController(withIdentifier: "ProfileViewID") as! UserHomeViewController
                self.present(vc, animated: true, completion: nil)
            } else {
                let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Search", bundle: nil)
                let vc = eventStoryBoard.instantiateViewController(withIdentifier: "ProfileViewID") as! ConsultProfileController

                vc.IDUserConsulted = self.newfeeds[indexPath.row].user.id
                vc.nicknameUserConsulted = self.newfeeds[indexPath.row].user.nickname
                vc.descriptionUserConsulted = self.newfeeds[indexPath.row].user.description
                vc.pictureUserConsulted = self.newfeeds[indexPath.row].user.picture
                
                let navController = UINavigationController.init(rootViewController: vc)
                self.present(navController, animated: true, completion: nil)
            }
        }
            
        else if self.newfeeds[indexPath.row].message.lowercased().range(of: "following") != nil {
            let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Search", bundle: nil)
            
            let vc = eventStoryBoard.instantiateViewController(withIdentifier: "ProfileViewID") as! ConsultProfileController
            vc.IDUserConsulted = self.newfeeds[indexPath.row].followerInfo?.id
            vc.nicknameUserConsulted = self.newfeeds[indexPath.row].followerInfo?.nickname
           // vc.descriptionUserConsulted = self.newfeeds[indexPath.row].followerInfo.description \\ demander à ludo
            vc.pictureUserConsulted = self.newfeeds[indexPath.row].followerInfo?.picture
            
            let navController = UINavigationController.init(rootViewController: vc)
            
            self.present(navController, animated: true, completion: nil)

        }
            
        else if self.newfeeds[indexPath.row].message.lowercased().range(of: "playlist") != nil {
            // A faire
        }
    }
    
}
// MARK: Empty Table view
extension TimelineController: DZNEmptyDataSetSource {
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "No history available for the moment."
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
        return NSAttributedString(string: str, attributes: attrs)
    }
}

// MARK: Get Timeline of users
extension TimelineController {
    func GetTimelineUser() {
        
        let minDate = currentWeek.toString()
        let url = api.getRoute(SounityAPI.ROUTES.TIMELINE)
        let headers = [ "Authorization": "Bearer \(user.token)", "Content-Type": "application/x-www-form-urlencoded"]
        let parameters: [String : AnyObject] = ["id": user.id as AnyObject, "minDate": minDate as AnyObject]
        
        Alamofire.request(url, method: .get, parameters : parameters, headers : headers)
            .validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! != 200) {
                        let alert = DisplayAlert(title: "Timeline", message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        self.newfeeds.removeAll()
                        
                        for (_,subJson):(String, JSON) in jsonResponse {
                            let userJSON = subJson["user"]
                            let user = User(_description: "", _first_name: "", _last_name: "", _picture: userJSON["picture"].stringValue, _nickname: userJSON["nickname"].stringValue, _id: userJSON["id"].intValue, _id_country: 0, _id_language: 0)
                            if (subJson["event"].exists()) {
                                let eventJSON = subJson["event"]
                                let eventInfo = Event(_id: eventJSON["id"].intValue, _userMax: 0, _lat: eventJSON["latitude"].doubleValue, _long: eventJSON["longitude"].doubleValue, _started: false, _public: true, _name: eventJSON["name"].stringValue, _desc: eventJSON["description"].stringValue, _picture: eventJSON["picture"].stringValue, _created: eventJSON["created_date"].stringValue, _expired: eventJSON["created_date"].stringValue, _locationName: eventJSON["location_name"].stringValue, _isOwner: false, _isAdmin: false)
                                
                                self.newfeeds.append(newFeed(_message: subJson["message"].stringValue, _picture: subJson["picture"].stringValue, _created_date: subJson["create_date"].stringValue, _event: eventInfo, _user: user))
                            }
                            if (subJson["follower"].exists()) {
                                let followerJSON = subJson["follower"]
                                let followerInfo = Followers(_id:followerJSON["id"].intValue , _lastName: followerJSON["last_name"].stringValue, _nickName: followerJSON["nickname"].stringValue, _followedAt: followerJSON["followed_at"].stringValue, _firstName: followerJSON["first_name"].stringValue, _picture: followerJSON["picture"].stringValue, _follow: true)
                                
                                self.newfeeds.append(newFeed(_message: subJson["message"].stringValue, _picture: subJson["picture"].stringValue, _created_date: subJson["create_date"].stringValue, _follower: followerInfo, _user: user))
                            }
                                
                            else {
                                self.newfeeds.append(newFeed(_message: subJson["message"].stringValue, _picture: subJson["picture"].stringValue, _created_date: subJson["create_date"].stringValue, _user: user))
                            }
                        }
                        
                        self.tableview.endRefreshing(at: .top)
                        self.tableview.reloadData()
                    }
                }
        }
    }
}

// MARK: Navigations functions
extension TimelineController {
    @IBAction func showMenuAction(sender: UIButton) {
        let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Menu", bundle: nil)
        let menuVC = eventStoryBoard.instantiateViewController(withIdentifier: "MenuViewID")
        menuVC.modalPresentationStyle = .custom
        menuVC.transitioningDelegate = self
        if menuVC is GuillotineAnimationDelegate {
            presentationAnimator.animationDelegate = menuVC as? GuillotineAnimationDelegate
        }
        presentationAnimator.supportView = self.navigationController?.navigationBar
        presentationAnimator.presentButton = sender
        presentationAnimator.animationDuration = 0.3
        self.present(menuVC, animated: true, completion: nil)
    }
}

// MARK: Transition delegate functions
extension TimelineController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentationAnimator.mode = .presentation
        return presentationAnimator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentationAnimator.mode = .dismissal
        return presentationAnimator
    }
}

// MARK: Hide status bar
extension TimelineController {
    override var prefersStatusBarHidden : Bool {
        return true
    }
}

//MARK: Date formater
extension Date {
    func toString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter.string(from: self)
    }
}

// MARK: Class NewFeed
class newFeed {
    var message: String = ""
    var picture: String = ""
    var created_date: String = ""
    
    var eventInfo: Event?
    var followerInfo: Followers?
    var user: User
    
    init(_message: String, _picture: String, _created_date: String, _event: Event, _user: User) {
        self.message = _message
        self.picture = _picture
        self.created_date = _created_date
        self.eventInfo = _event
        self.user = _user
    }
    
    init(_message: String, _picture: String, _created_date: String, _follower: Followers, _user: User) {
        self.message = _message
        self.picture = _picture
        self.created_date = _created_date
        self.followerInfo = _follower
        self.user = _user
    }
    
    init(_message: String, _picture: String, _created_date: String, _user: User) {
        self.message = _message
        self.picture = _picture
        self.created_date = _created_date
        self.user = _user
    }
}
