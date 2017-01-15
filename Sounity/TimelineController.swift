//  TimelineController.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 17/11/2016.
//  Copyright © 2016 Fornieles Alix. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import GuillotineMenu
import SwiftMoment
import PullToRefresh
import StatefulViewController

class TimelineController: UIViewController, StatefulViewController {
    
    // MARK: Infos user connected
    var user = UserConnect()
    
    // MARK: API connection
    var api = SounityAPI()
    
    // MARK: Guillotine menu variable
    fileprivate lazy var presentationAnimator = GuillotineTransitionAnimation()
    
    // MARK: New Feeds Variables
    var newsFromWeekNumber: Int = 0
    var newfeeds = [newFeed]()
    var minDate = moment()
    var loading = false
    
    // MARK: StoryBoard UIElements
    @IBOutlet var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.alwaysBounceVertical = true
        self.collectionView.backgroundColor = UIColor(white: 0.95, alpha: 1)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadingView = LoadingView(_view: self.collectionView)
        setupInitialViewState()
        
        newfeeds.removeAll()
        collectionView.reloadData()
        
        self.GetTimelineUser()
    }
    
    deinit {
        self.collectionView.removePullToRefresh(collectionView.topPullToRefresh!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let refresher = PullToRefresh()
        collectionView.addPullToRefresh(refresher) {
            self.GetTimelineUser()
        }
        
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

// MARK: Override CollectionView functions
extension TimelineController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.newfeeds.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellId", for: indexPath as IndexPath) as! TimelineTableViewCell
        
        let feed = self.newfeeds[indexPath.row]
        cell.feed = feed
        
        cell.actionButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(TimelineController.consultFeed)))
        
        return cell
    }
    
    /// Func that allows to redirect to user to the relevant content
    ///
    /// - Parameter sender: sender related to the UICollectionViewCell
    func consultFeed(_ sender: UITapGestureRecognizer) {
        let touch = sender.location(in: self.collectionView)
        if let indexPath = self.collectionView.indexPathForItem(at: touch) {
            if (self.newfeeds[indexPath.row].eventInfo != nil) {
                let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Search", bundle: nil)
                
                let vc = eventStoryBoard.instantiateViewController(withIdentifier: "ConsultEventView") as! ConsultEventController
                vc.idEventSent = self.newfeeds[indexPath.row].eventInfo!.id
                let navController = UINavigationController.init(rootViewController: vc)
                self.present(navController, animated: true, completion: nil)
            } else if (self.newfeeds[indexPath.row].followerInfo != nil || self.newfeeds[indexPath.row].user.id != self.user.id) {
                let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Search", bundle: nil)
                let vc = eventStoryBoard.instantiateViewController(withIdentifier: "ProfileViewID") as! ConsultProfileController
                
                vc.IDUserConsulted = self.newfeeds[indexPath.row].user.id
                vc.nicknameUserConsulted = self.newfeeds[indexPath.row].user.nickname
                vc.descriptionUserConsulted = self.newfeeds[indexPath.row].user.description
                vc.pictureUserConsulted = self.newfeeds[indexPath.row].user.picture
                
                let navController = UINavigationController.init(rootViewController: vc)
                self.present(navController, animated: true, completion: nil)
            } else {
                let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Profile", bundle: nil)
                let vc = eventStoryBoard.instantiateViewController(withIdentifier: "ProfileViewID") as! UserHomeViewController
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 400)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height) && self.loading == false) {
            self.minDate = self.minDate.subtract(1, TimeUnit.Weeks)
            self.GetTimelineUser()
        }
    }
}

// MARK: Get Timeline of users
extension TimelineController {
    /// Allows to fetch the news feeds of the current user
    func GetTimelineUser() {
        
        let url = api.getRoute(SounityAPI.ROUTES.TIMELINE)
        let headers = [ "Authorization": "Bearer \(user.token)", "Content-Type": "application/x-www-form-urlencoded"]
        let parameters: [String : AnyObject] = ["id": user.id as AnyObject, "minDate": minDate.date.iso8601 as AnyObject]
        
        self.loading = true
        self.startLoading()

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
                        self.collectionView?.reloadData()
                        self.collectionView.endRefreshing(at: Position.top)
                        self.loading = false
                    }
                }
                else {
                    self.newfeeds.removeAll();
                    self.collectionView.endRefreshing(at: Position.top)
                    self.collectionView.reloadData()
                }
                self.endLoading()
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
        return false
    }
}
